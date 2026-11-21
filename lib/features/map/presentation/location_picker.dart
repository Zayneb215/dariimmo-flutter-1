import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/app_theme.dart';
import 'map_widgets.dart';

class LocationPicker extends StatefulWidget {
  final LatLng? initial;
  final ValueChanged<LatLng> onChanged;

  const LocationPicker({super.key, this.initial, required this.onChanged});

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _controller = MapController();
  LatLng? _point;
  bool _locating = false;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _point = widget.initial;
  }

  void _set(LatLng p, {double? zoom}) {
    setState(() {
      _point = p;
      _msg = null;
    });
    widget.onChanged(p);
    _controller.move(p, zoom ?? _controller.camera.zoom);
  }

  Future<void> _useMyLocation() async {
    setState(() {
      _locating = true;
      _msg = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _msg = 'Activez la localisation du téléphone.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _msg = 'Permission de localisation refusée.');
        return;
      }
      final pos = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 15),
      );
      _set(LatLng(pos.latitude, pos.longitude), zoom: 16);
    } catch (_) {
      setState(
        () => _msg =
            'Position introuvable. Touchez la carte pour placer l\'épingle.',
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 260,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: _point ?? tunisCenter,
                    initialZoom: _point == null ? 7 : 15,
                    onTap: (_, p) => _set(p),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: osmTileUrl,
                      userAgentPackageName: osmUserAgent,
                    ),
                    if (_point != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _point!,
                            width: 64,
                            height: 64,
                            child: const HouseMarker(),
                          ),
                        ],
                      ),
                    osmAttribution(),
                  ],
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: ElevatedButton.icon(
                    onPressed: _locating ? null : _useMyLocation,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      textStyle: const TextStyle(fontSize: 13),
                    ),
                    icon: _locating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: const Text('Ma position'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _point == null
              ? "Touchez la carte pour placer l'épingle (zoomez pour plus de précision)."
              : 'Position choisie ✅  ${_point!.latitude.toStringAsFixed(5)}, ${_point!.longitude.toStringAsFixed(5)}',
          style: TextStyle(
            fontSize: 13,
            color: _point == null ? AppTheme.grey : AppTheme.primary,
          ),
        ),
        if (_msg != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _msg!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
      ],
    );
  }
}
