import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/guest_prompt.dart';
import '../../auth/providers/auth_provider.dart';
import '../../listings/presentation/listing_card.dart';
import '../../listings/providers/listings_provider.dart';
import '../providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    if (user == null) {
      return const GuestPrompt(
        title: 'Favoris',
        headline: 'Connectez-vous pour voir vos listes de souhaits.',
        subtitle: 'Vous pouvez créer ou modifier des listes de souhaits une fois que vous êtes connecté.',
      );
    }

    final ids = ref.watch(favoriteIdsProvider);
    final listings = ref.watch(listingsProvider);

    return ColoredBox(
      color: const Color(0xFFF6F8FC),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Favoris',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Builder(
                builder: (_) {
                  if (ids.isLoading || listings.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (ids.hasError || listings.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Impossible de charger vos favoris.\n${ids.error ?? listings.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final favIds = ids.value ?? <String>{};
                  final items = (listings.value ?? [])
                      .where((l) => favIds.contains(l.id))
                      .toList();

                  if (items.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite_border,
                              size: 64,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Vous n'avez pas encore de favoris.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Touchez le ❤️ sur une annonce pour la retrouver ici.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.grey),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => context.go('/explore'),
                              child: const Text('Découvrir les annonces'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) => ListingCard(listing: items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
