import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/location_service.dart';

class LocationSharingScreen extends StatefulWidget {
  const LocationSharingScreen({super.key});

  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    LocationService.instance.startRealTimeGpsTracking();
  }

  @override
  void dispose() {
    LocationService.instance.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BẢN ĐỒ & ĐỊNH VỊ GPS THẬT'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Lấy vị trí GPS thật',
            onPressed: () async {
              await LocationService.instance.fetchRealGpsLocation();
              final loc = LocationService.instance.currentLocation;
              _mapController.move(LatLng(loc.latitude, loc.longitude), 16.0);
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: LocationService.instance,
        builder: (context, _) {
          final locService = LocationService.instance;
          final loc = locService.currentLocation;
          final point = LatLng(loc.latitude, loc.longitude);

          return Column(
            children: [
              if (locService.permissionMessage.isNotEmpty)
                Container(
                  color: Colors.amber.shade100,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          locService.permissionMessage,
                          style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => locService.fetchRealGpsLocation(),
                        child: const Text('Cấp quyền'),
                      ),
                    ],
                  ),
                ),

              // REAL Interactive OpenStreetMap View
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: point,
                        initialZoom: 15.0,
                        maxZoom: 19.0,
                        minZoom: 3.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.trieuthimaichi',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: point,
                              width: 80,
                              height: 80,
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: loc.inSafeZone ? Colors.teal.shade800 : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                    ),
                                    child: Text(
                                      loc.childName,
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 40,
                                    color: loc.inSafeZone ? Colors.teal : Colors.red,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Map Control Floating Buttons
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'recenter',
                            backgroundColor: Colors.teal.shade800,
                            foregroundColor: Colors.white,
                            onPressed: () {
                              _mapController.move(point, 16.0);
                            },
                            child: const Icon(Icons.gps_fixed),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Location Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('📍 Tọa Độ GPS Thực Tế', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: loc.inSafeZone ? Colors.teal.shade50 : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            loc.inSafeZone ? 'An Toàn 🟢' : 'Cảnh Báo 🔴',
                            style: TextStyle(
                              color: loc.inSafeZone ? Colors.teal : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc.address,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: locService.isFetchingGps
                                ? null
                                : () async {
                                    await locService.fetchRealGpsLocation();
                                    _mapController.move(LatLng(locService.currentLocation.latitude, locService.currentLocation.longitude), 16.0);
                                  },
                            icon: locService.isFetchingGps
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.my_location),
                            label: const Text('ĐỊNH VỊ GPS THẬT'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
