import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _resetPassword(BuildContext context) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    try {
      FirebaseAuth.instance.setLanguageCode('fr');
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Un email a été envoyé à $email.')),
      );
    } on FirebaseAuthException {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'envoyer l'email.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final hasPassword =
        user?.providerData.any((p) => p.providerId == 'password') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          ListTile(
            leading: const Icon(Icons.person_outline, color: AppTheme.primary),
            title: const Text('Modifier le profil'),
            subtitle: const Text('Photo, nom, numéro de téléphone'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/edit-profile'),
          ),
          if (hasPassword)
            ListTile(
              leading: const Icon(Icons.lock_outline, color: AppTheme.primary),
              title: const Text('Changer le mot de passe'),
              subtitle: const Text('Vous recevrez un lien par email'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _resetPassword(context),
            ),
          const ListTile(
            leading: Icon(Icons.info_outline, color: AppTheme.primary),
            title: Text('À propos'),
            subtitle: Text('DariImmo · version 1.0.0'),
          ),
        ],
      ),
    );
  }
}
