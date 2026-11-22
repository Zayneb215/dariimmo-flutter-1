import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/user_avatar.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _avatarBase64 = '';
  String _avatarUrl = '';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider).value;
    final user = FirebaseAuth.instance.currentUser;
    _nameCtrl.text = p?.name.isNotEmpty == true ? p!.name : (user?.displayName ?? '');
    _phoneCtrl.text = p?.phone ?? '';
    _avatarBase64 = p?.avatarBase64 ?? '';
    _avatarUrl = p?.avatarUrl ?? user?.photoURL ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 600 * 1024) {
        setState(() => _error = 'Photo trop lourde, choisissez-en une autre.');
        return;
      }
      setState(() {
        _avatarBase64 = base64Encode(bytes);
        _error = null;
      });
    } catch (e) {
      setState(() => _error = "Impossible d'ouvrir la galerie.");
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final name = _nameCtrl.text.trim();
      await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .set({
        'name': name,
        'email': user.email ?? '',
        'phone': _phoneCtrl.text.trim(),
        'avatarBase64': _avatarBase64,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 10));
      await user.updateDisplayName(name);
      if (!mounted) return;
      context.pop();
    } catch (e) {
      setState(() => _error = "Enregistrement impossible. Vérifiez votre connexion.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      children: [
                        UserAvatar(
                            base64: _avatarBase64, url: _avatarUrl, radius: 56),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                                color: AppTheme.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt,
                                size: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _pickPhoto,
                  child: const Text('Changer la photo'),
                ),
                const SizedBox(height: 16),
                const Text('Nom complet',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Ahmed Ben Ali'),
                  validator: (v) => (v == null || v.trim().length < 2)
                      ? 'Entrez votre nom'
                      : null,
                ),
                const SizedBox(height: 16),
                const Text('Numéro de téléphone',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                      hintText: '+216 20 123 456', prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) {
                    final t = (v ?? '').replaceAll(RegExp(r'[\s+]'), '');
                    if (t.isEmpty) return null;
                    if (!RegExp(r'^\d{8,12}$').hasMatch(t)) {
                      return 'Numéro invalide';
                    }
                    return null;
                  },
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Enregistrer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}