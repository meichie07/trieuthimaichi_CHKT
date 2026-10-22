import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final List<Map<String, dynamic>> _tickets = [
    {
      'id': 'TK-101',
      'parent': 'Lê Văn Phụ Huynh',
      'issue': 'Hỗ trợ ghép nối thiết bị iPad mini 6 cho trẻ',
      'time': '10 phút trước',
      'status': 'Chờ xử lý',
    },
    {
      'id': 'TK-102',
      'parent': 'Trần Thị Thu',
      'issue': 'Kiểm tra tín hiệu vị trí GPS chập chờn',
      'time': '30 phút trước',
      'status': 'Đang hỗ trợ',
    },
  ];

  void _handleLogout() async {
    await AuthService.instance.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHBOARD NHÂN VIÊN'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.teal.shade50,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.teal.shade700,
                  child: const Icon(Icons.badge, color: Colors.white),
                ),
                title: Text(currentUser?.fullName ?? 'Nhân viên chăm sóc', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Bộ phận: Hỗ trợ Kỹ thuật & Xác minh thiết bị ghép nối'),
              ),
            ),
            const SizedBox(height: 20),

            const Text('📋 Danh sách yêu cầu hỗ trợ khách hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tickets.length,
              itemBuilder: (context, index) {
                final ticket = _tickets[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: ticket['status'] == 'Chờ xử lý' ? Colors.orange : Colors.green,
                      child: const Icon(Icons.support_agent, color: Colors.white),
                    ),
                    title: Text('${ticket['id']} - ${ticket['parent']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${ticket['issue']}\nThời gian: ${ticket['time']}'),
                    isThreeLine: true,
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Đã tiếp nhận xử lý ${ticket['id']}')),
                        );
                      },
                      child: const Text('Xử lý'),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
