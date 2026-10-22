class AppRuleModel {
  final String id;
  final String childId;
  final String appName;
  final String packageName;
  final int timeLimitMinutes;
  final int usedMinutes;
  final bool isBlocked;
  final String category;

  AppRuleModel({
    required this.id,
    required this.childId,
    required this.appName,
    required this.packageName,
    this.timeLimitMinutes = 60,
    this.usedMinutes = 20,
    this.isBlocked = false,
    this.category = 'Giải trí',
  });

  AppRuleModel copyWith({
    String? id,
    String? childId,
    String? appName,
    String? packageName,
    int? timeLimitMinutes,
    int? usedMinutes,
    bool? isBlocked,
    String? category,
  }) {
    return AppRuleModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      timeLimitMinutes: timeLimitMinutes ?? this.timeLimitMinutes,
      usedMinutes: usedMinutes ?? this.usedMinutes,
      isBlocked: isBlocked ?? this.isBlocked,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'appName': appName,
      'packageName': packageName,
      'timeLimitMinutes': timeLimitMinutes,
      'usedMinutes': usedMinutes,
      'isBlocked': isBlocked,
      'category': category,
    };
  }

  factory AppRuleModel.fromJson(Map<String, dynamic> json) {
    return AppRuleModel(
      id: json['id']?.toString() ?? '',
      childId: json['childId']?.toString() ?? '',
      appName: json['appName']?.toString() ?? 'Ứng dụng',
      packageName: json['packageName']?.toString() ?? 'com.example.app',
      timeLimitMinutes: int.tryParse(json['timeLimitMinutes']?.toString() ?? '60') ?? 60,
      usedMinutes: int.tryParse(json['usedMinutes']?.toString() ?? '0') ?? 0,
      isBlocked: json['isBlocked'] == true || json['isBlocked']?.toString() == 'true',
      category: json['category']?.toString() ?? 'Khác',
    );
  }
}
