enum UserRole { admin, employee, parent, child }

class UserModel {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final UserRole role;
  final String? pairingCode;
  final String? phoneNumber;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    required this.role,
    this.pairingCode,
    this.phoneNumber,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static UserRole roleFromString(String roleStr) {
    switch (roleStr.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'employee':
      case 'nhan_vien':
      case 'nhanvien':
        return UserRole.employee;
      case 'child':
      case 'tre_em':
      case 'treem':
        return UserRole.child;
      case 'parent':
      case 'phu_huynh':
      case 'khach_hang':
      case 'khachhang':
      default:
        return UserRole.parent;
    }
  }

  static String roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.employee:
        return 'employee';
      case UserRole.child:
        return 'child';
      case UserRole.parent:
        return 'parent';
    }
  }

  static String roleToDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Quản trị viên (Admin)';
      case UserRole.employee:
        return 'Nhân viên hỗ trợ';
      case UserRole.child:
        return 'Tài khoản Trẻ em';
      case UserRole.parent:
        return 'Phụ huynh / Khách hàng';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'fullName': fullName,
      'role': roleToString(role),
      'pairingCode': pairingCode,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ?? json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? json['username']?.toString() ?? 'Người dùng',
      role: roleFromString(json['role']?.toString() ?? 'parent'),
      pairingCode: json['pairingCode']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
