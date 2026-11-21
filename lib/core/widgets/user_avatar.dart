import 'dart:convert';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? base64;
  final String? url;
  final double radius;

  const UserAvatar({super.key, this.base64, this.url, this.radius = 48});

  @override
  Widget build(BuildContext context) {
    ImageProvider? provider;
    if (base64 != null && base64!.isNotEmpty) {
      provider = MemoryImage(base64Decode(base64!));
    } else if (url != null && url!.isNotEmpty) {
      provider = NetworkImage(url!);
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE8EEF8),
      backgroundImage: provider,
      child: provider == null
          ? Icon(Icons.person, size: radius, color: AppTheme.primary)
          : null,
    );
  }
}