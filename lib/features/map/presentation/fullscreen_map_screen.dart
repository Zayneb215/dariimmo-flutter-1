import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import 'map_widgets.dart';

class FullscreenMapScreen extends StatelessWidget {
  final LatLng point;
  final String title;

  const FullscreenMapScreen({super.key, required this.point, required this.title});

  Future<void> _openMaps(BuildContext context) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${point.latitude},${point.longitude}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir l'application de cartes.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: point,
          initialZoom: 16,
          minZoom: 3,
          maxZoom: 19,
        ),
        children: [
          TileLayer(urlTemplate: osmTileUrl, userAgentPackageName: osmUserAgent),
          MarkerLayer(
            markers: [
              Marker(point: point, width: 64, height: 64, child: const HouseMarker()),
            ],
          ),
          osmAttribution(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMaps(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.directions),
        label: const Text('Itinéraire'),
      ),
    );
  }
}