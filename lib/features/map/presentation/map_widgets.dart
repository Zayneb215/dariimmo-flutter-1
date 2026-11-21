import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';

const osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const osmUserAgent = 'com.dariimmo.app';
const tunisCenter = LatLng(36.8065, 10.1815);

Widget osmAttribution() => RichAttributionWidget(
      attributions: [TextSourceAttribution('© OpenStreetMap')],
    );

/// Épingle "maison" (cercle bleu marine + halo)
class HouseMarker extends StatelessWidget {
  const HouseMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x330B3C8C),
      ),
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primary,
        ),
        child: const Icon(Icons.home, color: Colors.white, size: 22),
      ),
    );
  }
}