import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final profile = ref.watch(profileProvider).value;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: user == null
            ? _guest(context)
            : _connected(context, user, profile),
      ),
    );
  }

  // ---------- Visiteur ----------
  Widget _guest(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text('Profile',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        const Text(
          'Commencez votre recherche du logement parfait en vous connectant ou en créant un compte dès maintenant !',
          style: TextStyle(fontSize: 15, color: AppTheme.grey),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.push('/login'),
          child: const Text('Connexion'),
        ),
        const SizedBox(height: 16),
        Row(children: [
          const Text("Vous n'avez pas de compte ? ",
              style: TextStyle(color: AppTheme.grey)),
          GestureDetector(
            onTap: () => context.push('/login'),
            child: const Text("S'inscrire",
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline)),
          ),
        ]),
        const SizedBox(height: 24),
        InkWell(
          onTap: () => context.push('/login'),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E5E5)),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Publier votre propriété',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    SizedBox(height: 6),
                    Text('Publiez gratuitement et recevez des offres rapidement.',
                        style: TextStyle(color: AppTheme.grey)),
                  ],
                ),
              ),
              Icon(Icons.home_work_outlined,
                  size: 48, color: AppTheme.primary),
            ]),
          ),
        ),
      ],
    );
  }

  // ---------- Connecté ----------
  Widget _connected(BuildContext context, User user, UserProfile? p) {
    final name = (p?.name.isNotEmpty == true)
        ? p!.name
        : (user.displayName ?? 'Utilisateur');
    final phone = p?.phone ?? '';

    return Column(
      children: [
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => context.push('/edit-profile'),
          child: Stack(
            children: [
              UserAvatar(
                base64: p?.avatarBase64,
                url: (p?.avatarUrl.isNotEmpty == true)
                    ? p!.avatarUrl
                    : user.photoURL,
                radius: 52,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                      color: AppTheme.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.edit, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(name,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary)),
        const SizedBox(height: 4),
        Text(user.email ?? '',
            style: const TextStyle(color: AppTheme.grey, fontSize: 14)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => context.push('/edit-profile'),
          child: Text(
            phone.isEmpty ? 'Ajouter un numéro' : phone,
            style: TextStyle(
                fontSize: 14,
                color: phone.isEmpty ? AppTheme.primary : AppTheme.grey),
          ),
        ),
        const SizedBox(height: 36),
        _MenuTile(
          icon: Icons.home_work_outlined,
          label: 'Mes annonces',
          onTap: () => context.push('/my-listings'),
        ),
        const _Line(),
        _MenuTile(
          icon: Icons.settings_outlined,
          label: 'Paramètres',
          onTap: () => context.push('/settings'),
        ),
        const SizedBox(height: 28),
        _MenuTile(
          icon: Icons.logout,
          label: 'Déconnexion',
          color: const Color(0xFFD64545),
          showChevron: false,
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Se déconnecter',
                  style: TextStyle(color: Color(0xFFD64545)))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool showChevron;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppTheme.dark,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, color: color == AppTheme.dark ? AppTheme.primary : color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600, color: color)),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right, color: AppTheme.grey),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: Color(0xFFEDEDED));
}