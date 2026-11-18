import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../controllers/location_controller.dart';

/// Screen allowing the user to select coordinates on a map
class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _tunisCenter = LatLng(36.8065, 10.1815);
  final MapController _mapController = MapController();
  LatLng? _selectedPoint;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedPoint = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedPoint = point;
    });
  }

  Future<void> _handleUseCurrentLocation() async {
    final locationController = context.read<LocationController>();
    final success = await locationController.useCurrentLocation();

    if (!mounted) return;

    if (success && locationController.hasSelection) {
      final newPoint = LatLng(
        locationController.selectedLat!,
        locationController.selectedLng!,
      );
      setState(() {
        _selectedPoint = newPoint;
      });
      _mapController.move(newPoint, 15.0);
    } else if (locationController.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locationController.errorMessage!),
          action: locationController.isPermissionPermanentlyDenied
              ? SnackBarAction(
                  label: 'Settings',
                  onPressed: () => locationController.openAppSettings(),
                )
              : null,
        ),
      );
    }
  }

  void _confirmSelection() {
    if (_selectedPoint == null) return;
    final locationController = context.read<LocationController>();
    locationController.setPosition(
      _selectedPoint!.latitude,
      _selectedPoint!.longitude,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final locationController = context.watch<LocationController>();
    final center = _selectedPoint ?? _tunisCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Delivery Location'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.0,
              onTap: _handleTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'fl',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              SimpleAttributionWidget(
                source: const Text('OpenStreetMap contributors'),
              ),
            ],
          ),

          // Floating Current Location Button
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'my_location_btn',
              onPressed: locationController.isLoading
                  ? null
                  : _handleUseCurrentLocation,
              child: locationController.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),

          // Bottom Bar for Confirmation
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedPoint == null
                          ? 'Tap anywhere on the map to set location'
                          : 'Selected: ${_selectedPoint!.latitude.toStringAsFixed(4)}, ${_selectedPoint!.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _selectedPoint == null ? null : _confirmSelection,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Use this location'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
