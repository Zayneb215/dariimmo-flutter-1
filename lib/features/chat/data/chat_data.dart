import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../listings/data/listing.dart';

class Conversation {
  final String id;
  final List<String> participants;
  final String buyerId;
  final String sellerId;
  final String buyerName;
  final String sellerName;
  final String listingId;
  final String listingTitle;
  final String listingImage;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? updatedAt;
  final Map<String, int> unread;

  const Conversation({
    required this.id,
    required this.participants,
    required this.buyerId,
    required this.sellerId,
    required this.buyerName,
    required this.sellerName,
    required this.listingId,
    required this.listingTitle,
    required this.listingImage,
    required this.lastMessage,
    required this.lastSenderId,
    required this.updatedAt,
    required this.unread,
  });

  factory Conversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    // tolérant : "unread" peut être absent ou d'un autre type
    final unread = <String, int>{};
    final rawUnread = d['unread'];
    if (rawUnread is Map) {
      rawUnread.forEach((k, v) {
        if (v is num) unread['$k'] = v.toInt();
      });
    }

    final rawParts = d['participants'];
    final participants = rawParts is List
        ? rawParts.whereType<String>().toList()
        : <String>[];

    return Conversation(
      id: doc.id,
      participants: participants,
      buyerId: d['buyerId'] as String? ?? '',
      sellerId: d['sellerId'] as String? ?? '',
      buyerName: d['buyerName'] as String? ?? '',
      sellerName: d['sellerName'] as String? ?? '',
      listingId: d['listingId'] as String? ?? '',
      listingTitle: d['listingTitle'] as String? ?? '',
      listingImage: d['listingImage'] as String? ?? '',
      lastMessage: d['lastMessage'] as String? ?? '',
      lastSenderId: d['lastSenderId'] as String? ?? '',
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      unread: unread,
    );
  }

  /// Uid de l'autre personne (calculé depuis "participants")
  String otherUid(String myUid) {
    for (final p in participants) {
      if (p.isNotEmpty && p != myUid) return p;
    }
    if (buyerId.isNotEmpty && buyerId != myUid) return buyerId;
    if (sellerId.isNotEmpty && sellerId != myUid) return sellerId;
    return '';
  }

  /// Nom de l'autre personne s'il est stocké dans la conversation, sinon null
  String? otherNameOrNull(String myUid) {
    final n = (myUid == buyerId) ? sellerName : buyerName;
    return n.isNotEmpty ? n : null;
  }

  /// Nombre de messages non lus pour cet utilisateur
  int unreadFor(String uid) => unread[uid] ?? 0;
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime? createdAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      text: d['text'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ChatService {
  /// Une conversation par (annonce + acheteur) : jamais de doublon
  static String conversationId(String listingId, String buyerId) =>
      '${listingId}_$buyerId';

  /// Crée la conversation si elle n'existe pas, et retourne son id
  static Future<String> openConversation(Listing l) async {
    final me = FirebaseAuth.instance.currentUser!;
    final id = conversationId(l.id, me.uid);

    await FirebaseFirestore.instance
        .collection('conversations')
        .doc(id)
        .set({
          'participants': [me.uid, l.ownerId],
          'buyerId': me.uid,
          'sellerId': l.ownerId,
          'buyerName': (me.displayName?.isNotEmpty ?? false)
              ? me.displayName
              : (me.email?.split('@').first ?? 'Utilisateur'),
          'sellerName': l.ownerName.isNotEmpty ? l.ownerName : 'Propriétaire',
          'listingId': l.id,
          'listingTitle': l.title,
          'listingImage': l.imageUrls.isNotEmpty ? l.imageUrls.first : '',
        }, SetOptions(merge: true))
        .timeout(const Duration(seconds: 15));

    return id;
  }

  /// Envoie un message et ajoute +1 au compteur "non lus" du destinataire
  static Future<void> send(String convId, String text, String otherUid) async {
    if (otherUid.isEmpty) throw StateError('no-recipient');

    final me = FirebaseAuth.instance.currentUser!;
    final db = FirebaseFirestore.instance;
    final conv = db.collection('conversations').doc(convId);

    final batch = db.batch();
    batch.set(conv.collection('messages').doc(), {
      'senderId': me.uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(conv, {
      'lastMessage': text,
      'lastSenderId': me.uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'unread.$otherUid': FieldValue.increment(1),
    });
    await batch.commit().timeout(const Duration(seconds: 15));
  }

  /// Met mon compteur de messages non lus à 0
  static Future<void> markRead(String convId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(convId)
          .update({'unread.$uid': 0});
    } catch (_) {}
  }
}
