import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

/// profiles/{uid}/favorites/{listingId}
CollectionReference<Map<String, dynamic>> _favCol(String uid) =>
    FirebaseFirestore.instance
        .collection('profiles')
        .doc(uid)
        .collection('favorites');
final favoriteIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(<String>{});

  return _favCol(user.uid)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.id).toSet());
});

class FavoritesService {
  /// Ajoute ou retire une annonce des favoris
  static Future<void> toggle(
    String listingId, {
    required bool currentlyFavorite,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = _favCol(uid).doc(listingId);

    if (currentlyFavorite) {
      await ref.delete().timeout(const Duration(seconds: 10));
    } else {
      await ref
          .set({
            'listingId': listingId,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 10));
    }
  }
}
