import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> _systemUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSystemUsers();
  }

  void _loadSystemUsers() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getRegisteredUsers();
    if (mounted) {
      setState(() {
        _systemUsers = list;
        _isLoading = false;
      });
    }
  }

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

  // --- ADD USER DIALOG ---
  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    UserRole selectedRole = UserRole.parent;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: Colors.indigo),
              SizedBox(width: 8),
              Text('Thêm Tài Khoản Mới'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Địa chỉ Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Tên đăng nhập (Username)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Mật khẩu'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Vai trò (Phân quyền)'),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem<UserRole>(
                      value: role,
                      child: Text(UserModel.roleToDisplayName(role)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;

                final messenger = ScaffoldMessenger.of(context);
                await ApiService.register(
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text.isEmpty ? '123456' : passCtrl.text,
                  username: usernameCtrl.text.trim().isEmpty ? emailCtrl.text.split('@').first : usernameCtrl.text.trim(),
                  fullName: nameCtrl.text.trim(),
                  role: selectedRole,
                );

                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (mounted) {
                  _loadSystemUsers();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('✅ Đã thêm tài khoản "${nameCtrl.text}" (${UserModel.roleToDisplayName(selectedRole)}) vào danh sách hệ thống!'),
                      backgroundColor: Colors.indigo,
                    ),
                  );
                }
              },
              child: const Text('THÊM MỚI'),
            ),
          ],
        ),
      ),
    );
  }

  // --- UPDATE USER ROLE DIALOG ---
  void _showUpdateRoleDialog(Map<String, dynamic> user) {
    UserRole selectedRole = UserRole.parent;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text('Cập nhật phân quyền cho ${user['name']}'),
          content: DropdownButtonFormField<UserRole>(
            initialValue: selectedRole,
            decoration: const InputDecoration(labelText: 'Chọn vai trò mới'),
            items: UserRole.values.map((role) {
              return DropdownMenuItem<UserRole>(
                value: role,
                child: Text(UserModel.roleToDisplayName(role)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setDialogState(() => selectedRole = val);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  user['role'] = UserModel.roleToDisplayName(selectedRole);
                });
                await ApiService.saveRegisteredUsers(_systemUsers);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã đổi vai trò của ${user['name']} thành ${UserModel.roleToDisplayName(selectedRole)}')),
                  );
                }
              },
              child: const Text('LƯU'),
            ),
          ],
        ),
      ),
    );
  }

  // --- TOGGLE LOCK STATUS ---
  void _toggleLockUser(Map<String, dynamic> user) async {
    setState(() {
      user['status'] = user['status'] == 'Hoạt động' ? 'Đã khóa' : 'Hoạt động';
    });
    await ApiService.saveRegisteredUsers(_systemUsers);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật trạng thái tài khoản ${user['name']} thành "${user['status']}"')),
      );
    }
  }

  // --- DELETE USER ---
  void _deleteUser(Map<String, dynamic> user) async {
    setState(() {
      _systemUsers.removeWhere((u) => u['email'] == user['email']);
    });
    await ApiService.saveRegisteredUsers(_systemUsers);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xóa vĩnh viễn tài khoản ${user['name']}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUser = AuthService.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TRANG QUẢN TRỊ (ADMIN)'),
        backgroundColor: Colors.indigo.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadSystemUsers(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: Colors.indigo.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.indigo,
                          child: Icon(Icons.admin_panel_settings, color: Colors.white),
                        ),
                        title: Text(currentUser?.fullName ?? 'Quản trị viên', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Email: ${currentUser?.email ?? "admin@kidguard.com"}\nQuyền hạn: Toàn quyền quản trị Server API https://localhost:7048'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text('📊 Thống kê tổng quan hệ thống', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _buildStatCard('Tổng tài khoản', '${_systemUsers.length}', Icons.people, Colors.blue),
                        _buildStatCard('Thiết bị trẻ em', '856', Icons.tablet_android, Colors.purple),
                        _buildStatCard('API Status (7048)', 'Online (HTTPS)', Icons.cloud_done, Colors.green),
                        _buildStatCard('Cảnh báo ồn & SOS', '12 lượt', Icons.warning_amber, Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '👥 Quản lý tài khoản (${_systemUsers.length})',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onPressed: _showAddUserDialog,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Thêm User', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _systemUsers.length,
                      itemBuilder: (context, index) {
                        final user = _systemUsers[index];
                        final bool isBlocked = user['status'] == 'Đã khóa';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isBlocked ? Colors.grey.shade300 : Colors.indigo.shade100,
                              child: Text(
                                user['name'] != null && user['name'].toString().isNotEmpty ? user['name'][0] : 'U',
                                style: TextStyle(fontWeight: FontWeight.bold, color: isBlocked ? Colors.grey : Colors.indigo),
                              ),
                            ),
                            title: Text(user['name'] ?? '', style: TextStyle(fontWeight: FontWeight.bold, decoration: isBlocked ? TextDecoration.lineThrough : null)),
                            subtitle: Text('${user['email']} • ${user['role']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isBlocked ? Colors.red.shade100 : Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    user['status'] ?? 'Hoạt động',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isBlocked ? Colors.red.shade800 : Colors.green.shade800,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'Cập nhật phân quyền') _showUpdateRoleDialog(user);
                                    if (val == 'Khóa tài khoản') _toggleLockUser(user);
                                    if (val == 'Xóa vĩnh viễn') _deleteUser(user);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'Cập nhật phân quyền', child: Text('Cập nhật phân quyền')),
                                    PopupMenuItem(
                                      value: 'Khóa tài khoản',
                                      child: Text(isBlocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'Xóa vĩnh viễn',
                                      child: Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}
