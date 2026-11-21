import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../data/chat_data.dart';

/// Mes conversations (Inbox), seulement celles qui ont au moins un message
final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(<Conversation>[]);

  return FirebaseFirestore.instance
      .collection('conversations')
      .where('participants', arrayContains: user.uid)
      .snapshots()
      .map((snap) {
        final list = snap.docs
            .map(Conversation.fromDoc)
            .where((c) => c.lastMessage.isNotEmpty)
            .toList();
        list.sort(
          (a, b) => (b.updatedAt ?? DateTime.now()).compareTo(
            a.updatedAt ?? DateTime.now(),
          ),
        );
        return list;
      });
});

/// Une conversation par id
final conversationProvider = StreamProvider.family<Conversation?, String>((
  ref,
  id,
) {
  return FirebaseFirestore.instance
      .collection('conversations')
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? Conversation.fromDoc(s) : null);
});

/// Les messages d'une conversation (temps réel)
final messagesProvider = StreamProvider.family<List<ChatMessage>, String>((
  ref,
  id,
) {
  return FirebaseFirestore.instance
      .collection('conversations')
      .doc(id)
      .collection('messages')
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
});

/// Nom d'un utilisateur (depuis profiles/{uid}), null si introuvable
final userNameProvider = FutureProvider.family<String?, String>((
  ref,
  uid,
) async {
  if (uid.isEmpty) return null;
  try {
    final d = await FirebaseFirestore.instance
        .collection('profiles')
        .doc(uid)
        .get();
    final n = d.data()?['name'] as String?;
    return (n != null && n.trim().isNotEmpty) ? n.trim() : null;
  } catch (_) {
    return null;
  }
});

/// Nom à afficher pour l'autre personne
/// (nom stocké dans la conversation, sinon son profil, sinon "Utilisateur")
String otherDisplayName(WidgetRef ref, Conversation c, String myUid) {
  final stored = c.otherNameOrNull(myUid);
  if (stored != null) return stored;
  final fetched = ref.watch(userNameProvider(c.otherUid(myUid))).value;
  return fetched ?? 'Utilisateur';
}

/// Nombre total de messages non lus (badge de la barre du bas)
final unreadCountProvider = Provider<int>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return 0;
  final convs =
      ref.watch(conversationsProvider).value ?? const <Conversation>[];
  return convs.fold<int>(0, (sum, c) => sum + c.unreadFor(user.uid));
});
