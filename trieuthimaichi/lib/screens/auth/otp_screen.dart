import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../dashboards/admin_dashboard.dart';
import '../dashboards/employee_dashboard.dart';
import '../dashboards/parent_dashboard.dart';
import '../dashboards/child_dashboard.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final String presetRole;

  const OtpScreen({
    super.key,
    required this.email,
    required this.presetRole,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading = false;
  String _generatedOtp = '';

  @override
  void initState() {
    super.initState();
    _generateAndPrefillRandomOtp();
  }

  void _generateAndPrefillRandomOtp() {
    final random = Random();
    _generatedOtp = List.generate(6, (_) => random.nextInt(10).toString()).join();
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = _generatedOtp[i];
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _handleVerifyOtp() async {
    final enteredCode = _controllers.map((c) => c.text.trim()).join();
    final otpCode = enteredCode.isEmpty ? _generatedOtp : enteredCode;

    setState(() => _isLoading = true);

    final response = await ApiService.verifyOtp(email: widget.email, otpCode: otpCode);

    setState(() => _isLoading = false);

    if (mounted && response['success'] == true) {
      final user = UserModel.fromJson(response['user']);
      final token = response['token'] ?? 'demo_token';

      await AuthService.instance.loginSuccess(user, token);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xác thực OTP thành công! Xin chào ${user.fullName} (${UserModel.roleToDisplayName(user.role)})'),
          backgroundColor: Colors.green.shade700,
        ),
      );

      Widget targetDashboard;
      switch (user.role) {
        case UserRole.admin:
          targetDashboard = const AdminDashboard();
          break;
        case UserRole.employee:
          targetDashboard = const EmployeeDashboard();
          break;
        case UserRole.child:
          targetDashboard = const ChildDashboard();
          break;
        case UserRole.parent:
          targetDashboard = const ParentDashboard();
          break;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => targetDashboard),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác Thực Mã OTP 2 Lớp'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.mark_email_read_outlined, size: 40, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Nhập mã xác thực OTP',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                children: [
                  const TextSpan(text: 'Mã xác thực 6 chữ số đã được gửi tới email: \n'),
                  TextSpan(
                    text: widget.email,
                    style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 6-Digit Random Prefilled OTP Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 45,
                  height: 55,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    enableSuggestions: false,
                    autocorrect: false,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _handleVerifyOtp,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('XÁC NHẬN & ĐĂNG NHẬP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),

            TextButton.icon(
              onPressed: () {
                setState(() {
                  _generateAndPrefillRandomOtp();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã tạo mã OTP ngẫu nhiên mới: $_generatedOtp')),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Gửi lại mã OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
