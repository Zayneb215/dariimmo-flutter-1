import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String avatarBase64;
  final String avatarUrl;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.avatarBase64,
    required this.avatarUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> d) => UserProfile(
    name: d['name'] as String? ?? '',
    email: d['email'] as String? ?? '',
    phone: d['phone'] as String? ?? '',
    avatarBase64: d['avatarBase64'] as String? ?? '',
    avatarUrl: d['avatarUrl'] as String? ?? '',
  );
}

final profileProvider = StreamProvider<UserProfile?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return FirebaseFirestore.instance
      .collection('profiles')
      .doc(user.uid)
      .snapshots()
      .map((s) => s.exists ? UserProfile.fromMap(s.data()!) : null);
});
