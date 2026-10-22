class ChildProfileModel {
  final String id;
  final String parentId;
  final String childName;
  final int age;
  final String deviceModel;
  final int batteryLevel;
  final bool isOnline;
  final int dailyMaxMinutes;
  final int usedMinutes;
  final String pairingCode;
  final DateTime lastActive;

  ChildProfileModel({
    required this.id,
    required this.parentId,
    required this.childName,
    required this.age,
    required this.deviceModel,
    this.batteryLevel = 85,
    this.isOnline = true,
    this.dailyMaxMinutes = 120,
    this.usedMinutes = 45,
    required this.pairingCode,
    DateTime? lastActive,
  }) : lastActive = lastActive ?? DateTime.now();

  ChildProfileModel copyWith({
    String? id,
    String? parentId,
    String? childName,
    int? age,
    String? deviceModel,
    int? batteryLevel,
    bool? isOnline,
    int? dailyMaxMinutes,
    int? usedMinutes,
    String? pairingCode,
    DateTime? lastActive,
  }) {
    return ChildProfileModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      childName: childName ?? this.childName,
      age: age ?? this.age,
      deviceModel: deviceModel ?? this.deviceModel,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isOnline: isOnline ?? this.isOnline,
      dailyMaxMinutes: dailyMaxMinutes ?? this.dailyMaxMinutes,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      pairingCode: pairingCode ?? this.pairingCode,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'childName': childName,
      'age': age,
      'deviceModel': deviceModel,
      'batteryLevel': batteryLevel,
      'isOnline': isOnline,
      'dailyMaxMinutes': dailyMaxMinutes,
      'usedMinutes': usedMinutes,
      'pairingCode': pairingCode,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  factory ChildProfileModel.fromJson(Map<String, dynamic> json) {
    return ChildProfileModel(
      id: json['id']?.toString() ?? '',
      parentId: json['parentId']?.toString() ?? '',
      childName: json['childName']?.toString() ?? 'Trẻ em',
      age: int.tryParse(json['age']?.toString() ?? '10') ?? 10,
      deviceModel: json['deviceModel']?.toString() ?? 'Samsung Galaxy Tab',
      batteryLevel: int.tryParse(json['batteryLevel']?.toString() ?? '85') ?? 85,
      isOnline: json['isOnline'] == true || json['isOnline']?.toString() == 'true',
      dailyMaxMinutes: int.tryParse(json['dailyMaxMinutes']?.toString() ?? '120') ?? 120,
      usedMinutes: int.tryParse(json['usedMinutes']?.toString() ?? '45') ?? 45,
      pairingCode: json['pairingCode']?.toString() ?? 'KID-8899',
      lastActive: json['lastActive'] != null
          ? DateTime.tryParse(json['lastActive'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
