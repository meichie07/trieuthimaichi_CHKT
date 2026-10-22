import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';

class LocationService extends ChangeNotifier {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  LocationModel _currentLocation = LocationModel(
    id: 'loc_real_01',
    childId: 'child_1',
    childName: 'Bé Minh Triết',
    latitude: 10.7769,
    longitude: 106.7009,
    address: 'Đang tải vị trí GPS...',
    inSafeZone: true,
    safeZoneName: 'Khu vực an toàn',
  );

  bool _isFetchingGps = false;
  String _permissionMessage = '';

  LocationModel get currentLocation => _currentLocation;
  bool get isFetchingGps => _isFetchingGps;
  String get permissionMessage => _permissionMessage;

  StreamSubscription<Position>? _positionSubscription;

  /// Fetch Real Device Position using Geolocator
  Future<void> fetchRealGpsLocation() async {
    _isFetchingGps = true;
    _permissionMessage = '';
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _permissionMessage = 'Dịch vụ GPS trên thiết bị chưa bật. Vui lòng bật GPS.';
        _isFetchingGps = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _permissionMessage = 'Quyền truy cập vị trí GPS bị từ chối.';
          _isFetchingGps = false;
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _permissionMessage = 'Quyền vị trí bị từ chối vĩnh viễn. Hãy cấp quyền trong Cài đặt.';
        _isFetchingGps = false;
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _updateLocationFromPosition(position);
    } catch (e) {
      debugPrint('Error getting real GPS location: $e');
      _permissionMessage = 'Không thể lấy vị trí GPS: $e';
    } finally {
      _isFetchingGps = false;
      notifyListeners();
    }
  }

  void startRealTimeGpsTracking() {
    fetchRealGpsLocation();

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      _updateLocationFromPosition(position);
    });
  }

  void stopTracking() {
    _positionSubscription?.cancel();
  }

  void _updateLocationFromPosition(Position pos) {
    // Check geofence status relative to center (10.7769, 106.7009) or current origin
    double distanceInMeters = Geolocator.distanceBetween(
      10.7769,
      106.7009,
      pos.latitude,
      pos.longitude,
    );

    bool inZone = distanceInMeters <= 1000; // 1km safe radius

    _currentLocation = LocationModel(
      id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
      childId: 'child_1',
      childName: 'Bé Minh Triết',
      latitude: pos.latitude,
      longitude: pos.longitude,
      address: 'Tọa độ GPS thực tế: ${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)} (Độ chính xác: ±${pos.accuracy.toStringAsFixed(0)}m)',
      inSafeZone: inZone,
      safeZoneName: inZone ? 'Vùng An Toàn Trường Học (Bán kính 1km)' : 'CẢNH BÁO: Ngoài Vùng An Toàn!',
      updatedAt: DateTime.now(),
    );

    notifyListeners();
  }
}
