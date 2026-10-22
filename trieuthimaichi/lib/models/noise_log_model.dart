enum NoiseLevelStatus { normal, warning, danger }

class NoiseLogModel {
  final String id;
  final String childId;
  final double decibels;
  final NoiseLevelStatus status;
  final DateTime timestamp;
  final String note;

  NoiseLogModel({
    required this.id,
    required this.childId,
    required this.decibels,
    required this.status,
    DateTime? timestamp,
    this.note = 'Môi trường góc học tập',
  }) : timestamp = timestamp ?? DateTime.now();

  static NoiseLevelStatus statusFromDecibels(double db) {
    if (db < 55) {
      return NoiseLevelStatus.normal;
    } else if (db <= 65) {
      return NoiseLevelStatus.warning;
    } else {
      return NoiseLevelStatus.danger;
    }
  }

  static String statusToText(NoiseLevelStatus status) {
    switch (status) {
      case NoiseLevelStatus.normal:
        return 'Yên tĩnh (Yên tâm học tập)';
      case NoiseLevelStatus.warning:
        return 'Tiếng ồn vừa phải';
      case NoiseLevelStatus.danger:
        return 'CẢNH BÁO: Quá ồn (>65 dB)';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'decibels': decibels,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'note': note,
    };
  }

  factory NoiseLogModel.fromJson(Map<String, dynamic> json) {
    final db = double.tryParse(json['decibels']?.toString() ?? '45.0') ?? 45.0;
    return NoiseLogModel(
      id: json['id']?.toString() ?? '',
      childId: json['childId']?.toString() ?? '',
      decibels: db,
      status: statusFromDecibels(db),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: json['note']?.toString() ?? 'Ghi nhận tự động',
    );
  }
}
