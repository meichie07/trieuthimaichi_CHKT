class LocationModel {
  final String id;
  final String childId;
  final String childName;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime updatedAt;
  final bool inSafeZone;
  final String safeZoneName;

  LocationModel({
    required this.id,
    required this.childId,
    required this.childName,
    required this.latitude,
    required this.longitude,
    required this.address,
    DateTime? updatedAt,
    this.inSafeZone = true,
    this.safeZoneName = 'Vùng an toàn - Trường học',
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'childName': childName,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'updatedAt': updatedAt.toIso8601String(),
      'inSafeZone': inSafeZone,
      'safeZoneName': safeZoneName,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id']?.toString() ?? '',
      childId: json['childId']?.toString() ?? '',
      childName: json['childName']?.toString() ?? 'Bé',
      latitude: double.tryParse(json['latitude']?.toString() ?? '10.7769') ?? 10.7769,
      longitude: double.tryParse(json['longitude']?.toString() ?? '106.7009') ?? 106.7009,
      address: json['address']?.toString() ?? 'Trường Tiểu học Nguyễn Du, Q1, TP.HCM',
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      inSafeZone: json['inSafeZone'] == true || json['inSafeZone']?.toString() == 'true',
      safeZoneName: json['safeZoneName']?.toString() ?? 'Trường học',
    );
  }
}
