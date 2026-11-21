import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/chat_data.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String convId;
  const ChatScreen({super.key, required this.convId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // dès qu'il y a des messages non lus (à l'ouverture ou pendant la
    // discussion), on les marque comme lus
    ref.listenManual<AsyncValue<Conversation?>>(
      conversationProvider(widget.convId),
      (prev, next) {
        final c = next.value;
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (c != null && uid != null && c.unreadFor(uid) > 0) {
          ChatService.markRead(widget.convId);
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _time(DateTime? d) {
    final t = d ?? DateTime.now();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;

    final me = FirebaseAuth.instance.currentUser;
    final conv = ref.read(conversationProvider(widget.convId)).value;
    if (me == null || conv == null) return;
    final otherUid = conv.buyerId == me.uid ? conv.sellerId : conv.buyerId;

    setState(() => _sending = true);
    _ctrl.clear();
    try {
      await ChatService.send(widget.convId, text, otherUid);
    } catch (e) {
      debugPrint('SEND ERROR: $e');
      _ctrl.text = text; // on remet le texte pour réessayer
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text("Message non envoyé. Vérifiez votre connexion."),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser;
    final conv = ref.watch(conversationProvider(widget.convId)).value;
    final messages = ref.watch(messagesProvider(widget.convId));
    final myUid = me?.uid ?? '';
    final otherUid = conv != null
        ? (conv.buyerId == myUid ? conv.sellerId : conv.buyerId)
        : null;
    final otherName = otherUid ?? 'Conversation';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              otherName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            if (conv != null)
              Text(
                conv.listingTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppTheme.grey),
              ),
          ],
        ),
        actions: [
          if (conv != null)
            IconButton(
              tooltip: "Voir l'annonce",
              icon: const Icon(Icons.home_work_outlined),
              onPressed: () => context.push('/listing/${conv.listingId}'),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Impossible de charger les messages.\n$e',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Écrivez votre premier message à $otherName.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.grey),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true, // le plus récent en bas
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final m = items[items.length - 1 - i];
                    return _bubble(m, m.senderId == myUid);
                  },
                );
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }

  Widget _bubble(ChatMessage m, bool mine) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppTheme.primary : const Color(0xFFF1F3F7),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              style: TextStyle(
                fontSize: 15,
                height: 1.3,
                color: mine ? Colors.white : AppTheme.dark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _time(m.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: mine ? Colors.white70 : AppTheme.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEDED))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Écrire un message...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
                icon: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
