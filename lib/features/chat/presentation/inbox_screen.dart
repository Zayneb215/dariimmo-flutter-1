import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/guest_prompt.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/chat_data.dart';
import '../providers/chat_provider.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  String _when(DateTime? d) {
    final t = d ?? DateTime.now();
    final now = DateTime.now();
    final sameDay =
        t.year == now.year && t.month == now.month && t.day == now.day;
    if (sameDay) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const GuestPrompt(
        title: 'Messages',
        headline: 'Connectez-vous pour voir les messages.',
        subtitle: 'Une fois connecté, vous trouverez vos messages ici.',
      );
    }

    final convs = ref.watch(conversationsProvider);
    final myUid = FirebaseAuth.instance.currentUser?.uid ?? user.uid;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Text(
              'Messages',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: convs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 64,
                            color: AppTheme.primary,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Aucun message pour le moment.',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Contactez un propriétaire depuis une annonce pour démarrer une conversation.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 84),
                  itemBuilder: (_, i) => _tile(context, items[i], myUid),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, Conversation c, String myUid) {
    final mine = c.lastSenderId == myUid;
    final unread = c.unreadFor(myUid);

    return InkWell(
      onTap: () => context.push('/chat/${c.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFE8EEF8),
              backgroundImage: c.listingImage.isNotEmpty
                  ? NetworkImage(c.listingImage)
                  : null,
              child: c.listingImage.isEmpty
                  ? const Icon(
                      Icons.home_work_outlined,
                      color: AppTheme.primary,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        // Consumer : pour pouvoir charger le nom depuis le profil
                        child: Consumer(
                          builder: (context, ref, _) => Text(
                            otherDisplayName(ref, c, myUid),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        _when(c.updatedAt),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: unread > 0
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: unread > 0 ? AppTheme.primary : AppTheme.grey,
                        ),
                      ),
                    ],
                  ),
                  if (c.listingTitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      c.listingTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${mine ? 'Vous : ' : ''}${c.lastMessage}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: unread > 0
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: unread > 0 ? AppTheme.dark : AppTheme.grey,
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(
                            minWidth: 22,
                            minHeight: 22,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
