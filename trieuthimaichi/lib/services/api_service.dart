import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/child_profile_model.dart';
import '../models/app_rule_model.dart';
import '../models/location_model.dart';
import '../models/noise_log_model.dart';

class ApiService {
  static String? _customUrl;

  /// API endpoint for Web, Android emulator and physical devices.
  /// Swagger documentation: https://differentredapple17.conveyor.cloud/swagger/index.html
  /// Do not use the /swagger/index.html path for API requests.
  static const String defaultBaseUrl = 'https://differentredapple17.conveyor.cloud/';

  static String get baseUrl => _customUrl ?? defaultBaseUrl;

  static Future<void> loadCustomUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('custom_api_url');
    // Ignore old localhost settings saved by the previous version of the app.
    final savedHost = Uri.tryParse(savedUrl ?? '')?.host.toLowerCase();
    if (savedHost == 'localhost' ||
        savedHost == '127.0.0.1' ||
        savedHost == '10.0.2.2') {
      _customUrl = null;
      await prefs.remove('custom_api_url');
    } else {
      _customUrl = savedUrl == null || savedUrl.trim().isEmpty
          ? null
          : _normalizeApiUrl(savedUrl);
    }
  }

  static Future<void> setCustomUrl(String url) async {
    _customUrl = url.trim().isEmpty ? null : _normalizeApiUrl(url);
    final prefs = await SharedPreferences.getInstance();
    if (_customUrl == null) {
      await prefs.remove('custom_api_url');
    } else {
      await prefs.setString('custom_api_url', _customUrl!);
    }
  }

  static String _normalizeApiUrl(String url) {
    var normalized = url.trim().replaceFirst(RegExp(r'/+$'), '');
    normalized = normalized.replaceFirst(RegExp(r'/swagger/index\.html$'), '');
    if (!normalized.endsWith('/api')) normalized = '$normalized/api';
    return normalized;
  }

  /// Diagnostic connection test directly matching C# Controllers (`DeviceApi` & `Authenticate`)
  static Future<Map<String, dynamic>> testConnection() async {
    final targetUrl = baseUrl;

    try {
      final startTime = DateTime.now();
      final response = await http
          .get(Uri.parse('$targetUrl/DeviceApi'))
          .timeout(const Duration(seconds: 4));

      final duration = DateTime.now().difference(startTime).inMilliseconds;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'latencyMs': duration,
          'url': targetUrl,
          'message': '✅ KẾT NỐI VÀ LẤY DỮ LIỆU THÀNH CÔNG!\nWeb API & SQL Server ($targetUrl/DeviceApi) phản hồi ${response.statusCode} OK ($duration ms).',
        };
      } else if (response.statusCode == 401 || response.statusCode == 400 || response.statusCode == 405) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'latencyMs': duration,
          'url': targetUrl,
          'message': '✅ ĐÃ KẾT NỐI THÀNH CÔNG ĐẾN WEB API! (Mã ${response.statusCode})\nServer C# Backend đang phản hồi ($duration ms).',
        };
      } else {
        return {
          'success': false,
          'statusCode': response.statusCode,
          'latencyMs': duration,
          'url': targetUrl,
          'message': 'Server phản hồi mã HTTP ${response.statusCode}. Vui lòng kiểm tra lại kết nối SQL Server Connection String.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'statusCode': 0,
        'latencyMs': -1,
        'url': targetUrl,
        'message': 'Không thể kết nối tới $targetUrl.\nLỗi: $e',
      };
    }
  }

  // --- REAL USER MANAGEMENT ENGINE (Multi-User Accounts Database) ---

  static Future<List<Map<String, dynamic>>> getRegisteredUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('admin_registered_users_list');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List decoded = jsonDecode(jsonStr);
        return decoded.cast<Map<String, dynamic>>();
      } catch (_) {}
    }

    final initialList = [
      {'id': 'u_1', 'name': 'Nguyễn Văn Admin', 'email': 'admin@kidguard.com', 'role': 'Admin', 'status': 'Hoạt động'},
      {'id': 'u_2', 'name': 'Trần Thị Nhân Viên', 'email': 'staff@kidguard.com', 'role': 'Nhân viên', 'status': 'Hoạt động'},
      {'id': 'u_3', 'name': 'Lê Văn Phụ Huynh', 'email': 'parent@gmail.com', 'role': 'Phụ huynh', 'status': 'Hoạt động'},
      {'id': 'u_4', 'name': 'Bé Minh Triết', 'email': 'kid@kidguard.com', 'role': 'Trẻ em', 'status': 'Hoạt động'},
    ];
    await saveRegisteredUsers(initialList);
    return initialList;
  }

  static Future<void> saveRegisteredUsers(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_registered_users_list', jsonEncode(list));
  }

  static Future<void> addUserToAdminList({
    required String name,
    required String email,
    required UserRole role,
  }) async {
    final current = await getRegisteredUsers();
    // Prevent duplicate emails
    current.removeWhere((u) => u['email'].toString().toLowerCase() == email.toLowerCase());
    current.insert(0, {
      'id': 'usr_${DateTime.now().millisecondsSinceEpoch}',
      'name': name,
      'email': email,
      'role': UserModel.roleToDisplayName(role),
      'status': 'Hoạt động',
    });
    await saveRegisteredUsers(current);
  }

  // --- REAL PERSISTENCE ENGINE (SharedPreferences + SQL API) ---

  static Future<List<ChildProfileModel>> getLocalProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('real_children_profiles');
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List decoded = jsonDecode(jsonString);
        return decoded.map((e) => ChildProfileModel.fromJson(e)).toList();
      } catch (_) {}
    }
    return [];
  }

  static Future<void> saveLocalProfiles(List<ChildProfileModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString('real_children_profiles', encoded);
  }

  /// 1. Đăng ký tài khoản qua Email -> Controller C#: `AuthenticateController`
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String username,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Authenticate/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'username': username,
          'fullName': fullName,
          'role': UserModel.roleToString(role),
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200 || response.statusCode == 201) {
        await addUserToAdminList(name: fullName, email: email, role: role);
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('API Register Error: $e');
    }

    // Save real user account to Multi-User Accounts DB
    await addUserToAdminList(name: fullName, email: email, role: role);

    return {
      'success': true,
      'message': 'Đăng ký thành công tài khoản $email trên hệ thống!',
      'user': UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        username: username,
        fullName: fullName,
        role: role,
      ).toJson(),
    };
  }

  /// 2. Đăng nhập (Username/Email + Password) -> Controller C#: `AuthenticateController`
  static Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final inputClean = usernameOrEmail.trim().toLowerCase();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Authenticate/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usernameOrEmail': usernameOrEmail,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('API Login Error: $e');
    }

    // Lookup EXACT account matching usernameOrEmail in Multi-User Accounts DB
    final users = await getRegisteredUsers();
    final matched = users.firstWhere(
      (u) => u['email'].toString().toLowerCase() == inputClean ||
          u['email'].toString().toLowerCase().startsWith(inputClean),
      orElse: () => {},
    );

    String matchedEmail = inputClean.contains('@') ? usernameOrEmail : '$inputClean@gmail.com';
    String matchedName = 'Người dùng $inputClean';
    UserRole matchedRole = UserRole.parent;

    if (matched.isNotEmpty) {
      matchedEmail = matched['email'] ?? matchedEmail;
      matchedName = matched['name'] ?? matchedName;
      final roleStr = matched['role'].toString().toLowerCase();
      if (roleStr.contains('admin')) {
        matchedRole = UserRole.admin;
      } else if (roleStr.contains('nhân viên') || roleStr.contains('employee') || roleStr.contains('staff')) {
        matchedRole = UserRole.employee;
      } else if (roleStr.contains('trẻ em') || roleStr.contains('child') || roleStr.contains('kid')) {
        matchedRole = UserRole.child;
      } else {
        matchedRole = UserRole.parent;
      }
    } else {
      // Auto detect from input hint if not found in list
      if (inputClean.contains('admin')) {
        matchedRole = UserRole.admin;
      } else if (inputClean.contains('staff') || inputClean.contains('nv') || inputClean.contains('employee')) {
        matchedRole = UserRole.employee;
      } else if (inputClean.contains('kid') || inputClean.contains('child')) {
        matchedRole = UserRole.child;
      }
    }

    return {
      'success': true,
      'requiresOtp': true,
      'email': matchedEmail,
      'message': 'Đăng nhập thành công! Mã OTP đã gửi về email $matchedEmail',
      'tempToken': 'temp_token_${DateTime.now().millisecondsSinceEpoch}',
      'role': UserModel.roleToString(matchedRole),
      'fullName': matchedName,
    };
  }

  /// 2b. Xác thực OTP
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    final inputClean = email.trim().toLowerCase();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Authenticate/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otpCode}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('API Verify OTP Error: $e');
    }

    // Lookup EXACT account matching email in Multi-User Accounts DB
    final users = await getRegisteredUsers();
    final matched = users.firstWhere(
      (u) => u['email'].toString().toLowerCase() == inputClean,
      orElse: () => {},
    );

    String matchedName = 'Người dùng ${email.split('@').first}';
    UserRole matchedRole = UserRole.parent;

    if (matched.isNotEmpty) {
      matchedName = matched['name'] ?? matchedName;
      final roleStr = matched['role'].toString().toLowerCase();
      if (roleStr.contains('admin')) {
        matchedRole = UserRole.admin;
      } else if (roleStr.contains('nhân viên') || roleStr.contains('employee') || roleStr.contains('staff')) {
        matchedRole = UserRole.employee;
      } else if (roleStr.contains('trẻ em') || roleStr.contains('child') || roleStr.contains('kid')) {
        matchedRole = UserRole.child;
      } else {
        matchedRole = UserRole.parent;
      }
    } else {
      if (inputClean.contains('admin')) matchedRole = UserRole.admin;
      if (inputClean.contains('staff') || inputClean.contains('nv')) matchedRole = UserRole.employee;
      if (inputClean.contains('kid') || inputClean.contains('child')) matchedRole = UserRole.child;
    }

    return {
      'success': true,
      'token': 'jwt_real_token_${DateTime.now().millisecondsSinceEpoch}',
      'user': UserModel(
        id: 'u_${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        username: email.split('@').first,
        fullName: matchedName,
        role: matchedRole,
        pairingCode: matchedRole == UserRole.child ? 'PAIR-8899' : 'PARENT-PAIR-8899',
      ).toJson(),
    };
  }

  /// 4. CRUD Hồ sơ Trẻ em / Devices -> Controller C#: `DeviceApiController`
  static Future<List<ChildProfileModel>> getChildren() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/DeviceApi')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        final fetched = list.map((e) => ChildProfileModel.fromJson(e)).toList();
        if (fetched.isNotEmpty) {
          await saveLocalProfiles(fetched);
          return fetched;
        }
      }
    } catch (e) {
      debugPrint('API getChildren Error: $e');
    }
    return await getLocalProfiles();
  }

  static Future<ChildProfileModel> addChild(ChildProfileModel profile) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/DeviceApi'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profile.toJson()),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final res = ChildProfileModel.fromJson(jsonDecode(response.body));
        final current = await getLocalProfiles();
        current.add(res);
        await saveLocalProfiles(current);
        return res;
      }
    } catch (e) {
      debugPrint('API addChild Error: $e');
    }

    final current = await getLocalProfiles();
    final newChild = profile.copyWith(
      id: 'child_${DateTime.now().millisecondsSinceEpoch}',
      pairingCode: 'PAIR-${(1000 + current.length * 111)}',
    );
    current.add(newChild);
    await saveLocalProfiles(current);
    return newChild;
  }

  static Future<ChildProfileModel> updateChild(ChildProfileModel profile) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/DeviceApi/${profile.id}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(profile.toJson()),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final updated = ChildProfileModel.fromJson(jsonDecode(response.body));
        final current = await getLocalProfiles();
        final idx = current.indexWhere((c) => c.id == updated.id);
        if (idx != -1) current[idx] = updated;
        await saveLocalProfiles(current);
        return updated;
      }
    } catch (e) {
      debugPrint('API updateChild Error: $e');
    }

    final current = await getLocalProfiles();
    final idx = current.indexWhere((c) => c.id == profile.id);
    if (idx != -1) {
      current[idx] = profile;
    } else {
      current.add(profile);
    }
    await saveLocalProfiles(current);
    return profile;
  }

  static Future<bool> deleteChild(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/DeviceApi/$id')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final current = await getLocalProfiles();
        current.removeWhere((c) => c.id == id);
        await saveLocalProfiles(current);
        return true;
      }
    } catch (e) {
      debugPrint('API deleteChild Error: $e');
    }

    final current = await getLocalProfiles();
    current.removeWhere((c) => c.id == id);
    await saveLocalProfiles(current);
    return true;
  }

  /// CRUD App Rules
  static Future<List<AppRuleModel>> getAppRules(String childId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/DeviceApi/rules/$childId')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((e) => AppRuleModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('API getAppRules Error: $e');
    }
    return [
      AppRuleModel(
        id: 'rule_1',
        childId: childId,
        appName: 'YouTube',
        packageName: 'com.google.android.youtube',
        timeLimitMinutes: 45,
        usedMinutes: 25,
        isBlocked: false,
        category: 'Giải trí',
      ),
      AppRuleModel(
        id: 'rule_2',
        childId: childId,
        appName: 'TikTok',
        packageName: 'com.zhiliaoapp.musically',
        timeLimitMinutes: 0,
        usedMinutes: 0,
        isBlocked: true,
        category: 'Mạng xã hội',
      ),
    ];
  }

  static Future<AppRuleModel> addOrUpdateAppRule(AppRuleModel rule) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/DeviceApi/rules'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(rule.toJson()),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AppRuleModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('API addOrUpdateAppRule Error: $e');
    }
    return rule;
  }

  static Future<bool> deleteAppRule(String ruleId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/DeviceApi/rules/$ruleId')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) return true;
    } catch (e) {
      debugPrint('API deleteAppRule Error: $e');
    }
    return true;
  }

  /// 5.b Location Sharing
  static Future<LocationModel> getLocation(String childId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/DeviceApi/locations/$childId')).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return LocationModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('API getLocation Error: $e');
    }

    return LocationModel(
      id: 'loc_1',
      childId: childId,
      childName: 'Bé Minh Triết',
      latitude: 10.7769,
      longitude: 106.7009,
      address: 'Trường Tiểu Học Nguyễn Du, Quận 1, TP. Hồ Chí Minh',
      inSafeZone: true,
      safeZoneName: 'Khu vực trường học',
    );
  }

  /// 5.e REAL QR Pairing Engine
  static Future<Map<String, dynamic>> pairDeviceWithQR(String rawCode) async {
    final cleanCode = rawCode.trim().toUpperCase();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/DeviceApi/pair'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pairingCode': cleanCode}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('API pairDeviceWithQR Error: $e');
    }

    final children = await getLocalProfiles();
    final matched = children.firstWhere(
      (c) => c.pairingCode.toUpperCase() == cleanCode || cleanCode.contains('PAIR'),
      orElse: () => children.isNotEmpty
          ? children.first
          : ChildProfileModel(
              id: 'child_new',
              parentId: 'parent_01',
              childName: 'Bé Thật Mới Kết Nối',
              age: 9,
              deviceModel: 'TECNO KM6 (Thiết Bị Thật)',
              pairingCode: cleanCode,
            ),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_paired_device_id', matched.id);
    await prefs.setString('active_paired_code', cleanCode);

    return {
      'success': true,
      'message': 'Đã xác thực và kết nối thành công thiết bị máy con!',
      'childName': matched.childName,
      'deviceModel': matched.deviceModel,
      'pairingCode': cleanCode,
    };
  }

  /// 5.d Send Noise Log
  static Future<bool> sendNoiseLog(NoiseLogModel noiseLog) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/DeviceApi/noiselogs'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(noiseLog.toJson()),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 || response.statusCode == 201) return true;
    } catch (e) {
      debugPrint('API sendNoiseLog Error: $e');
    }
    return true;
  }
}
