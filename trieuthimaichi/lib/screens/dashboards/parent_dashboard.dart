import 'package:flutter/material.dart';
import '../../models/child_profile_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../features/child_crud_screen.dart';
import '../features/location_sharing_screen.dart';
import '../features/noise_detector_screen.dart';
import '../features/qr_scanner_screen.dart';
import '../features/ai_study_guardian_screen.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;
  List<ChildProfileModel> _children = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  void _loadChildren() async {
    final list = await ApiService.getChildren();
    if (mounted) {
      setState(() {
        _children = list;
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

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('KID GUARD - PHỤ HUYNH', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        centerTitle: false,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _handleLogout,
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : RefreshIndicator(
              onRefresh: () async => _loadChildren(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.deepPurple, Colors.indigo.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withValues(alpha: 0.25),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.family_restroom_rounded, size: 36, color: Colors.white),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Xin chào, ${user?.fullName ?? "Phụ huynh"} 👋',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Đang bảo vệ ${_children.length} thiết bị trẻ em trực tuyến.',
                                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text('Danh Mục Chức Năng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _buildFeatureTile(
                          context,
                          title: 'Quản Lý Hồ Sơ & App',
                          subtitle: 'CRUD trẻ em & đặt giới hạn',
                          icon: Icons.edit_note_rounded,
                          color: Colors.blue.shade700,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildCrudScreen())),
                        ),
                        _buildFeatureTile(
                          context,
                          title: 'Chia Sẻ Vị Trí GPS',
                          subtitle: 'Định vị & Vùng an toàn',
                          icon: Icons.location_on_rounded,
                          color: Colors.teal.shade700,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationSharingScreen())),
                        ),
                        _buildFeatureTile(
                          context,
                          title: 'Đo Tiếng Ồn Góc Học',
                          subtitle: 'Decibel meter >65dB',
                          icon: Icons.graphic_eq_rounded,
                          color: Colors.orange.shade800,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NoiseDetectorScreen())),
                        ),
                        _buildFeatureTile(
                          context,
                          title: 'Quét & Tạo Mã QR',
                          subtitle: 'Ghép nối thiết bị nhanh',
                          icon: Icons.qr_code_scanner_rounded,
                          color: Colors.purple.shade700,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen())),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AiStudyGuardianScreen())),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal.shade900, Colors.green.shade900],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.security, size: 32, color: Colors.black87),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'TÍNH NĂNG MỚI SÁNG TẠO (1Đ)',
                                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Trình Duyệt An Toàn & Lọc Web Độc Hại',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Kiểm tra URL, bộ lọc từ khóa cấm cờ bạc & 18+',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.amber, size: 18),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Thiết Bị Trẻ Em Đang Quản Lý', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.deepPurple),
                          onPressed: _loadChildren,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _children.length,
                      itemBuilder: (context, index) {
                        final child = _children[index];
                        final usageRatio = (child.usedMinutes / child.dailyMaxMinutes).clamp(0.0, 1.0);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: Colors.deepPurple.shade100,
                                      child: Text(
                                        child.childName[0],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(child.childName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: child.isOnline ? Colors.green.shade100 : Colors.grey.shade300,
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  child.isOnline ? 'Trực tuyến' : 'Ngoại tuyến',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: child.isOnline ? Colors.green.shade800 : Colors.grey.shade700,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text('Thiết bị: ${child.deviceModel} • Pin: ${child.batteryLevel}%', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.settings_outlined, color: Colors.deepPurple),
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChildCrudScreen())),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Thời gian dùng máy:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text('${child.usedMinutes} / ${child.dailyMaxMinutes} phút', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: usageRatio,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey.shade200,
                                    color: usageRatio > 0.8 ? Colors.red : Colors.deepPurple,
                                  ),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const LocationSharingScreen()));
          if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const NoiseDetectorScreen()));
          if (index == 3) Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_rounded), label: 'Vị trí GPS'),
          BottomNavigationBarItem(icon: Icon(Icons.graphic_eq_rounded), label: 'Đo tiếng ồn'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner_rounded), label: 'Mã QR'),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
