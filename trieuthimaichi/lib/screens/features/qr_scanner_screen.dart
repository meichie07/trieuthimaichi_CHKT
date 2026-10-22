import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MobileScannerController _scannerController = MobileScannerController();
  final _codeController = TextEditingController(text: 'KID-7788');
  bool _isProcessing = false;
  bool _hasCameraPermission = false;
  bool _isCheckingPermission = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _codeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasCameraPermission = status.isGranted;
        _isCheckingPermission = false;
      });
    }
  }

  void _onQrDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String rawCode = barcodes.first.rawValue ?? '';
    if (rawCode.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _codeController.text = rawCode;
    });

    _processPairingCode(rawCode);
  }

  void _processPairingCode(String code) async {
    final res = await ApiService.pairDeviceWithQR(code);

    if (mounted) {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 8),
              Expanded(child: Text('GHÉP NỐI THÀNH CÔNG!')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📱 Mã thiết bị: $code', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('👦 Trẻ em: ${res['childName'] ?? "Bé Minh Triết"}'),
              Text('💻 Thiết bị: ${res['deviceModel'] ?? "Samsung Galaxy Tab A8"}'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10)),
                child: const Text(
                  '✅ Máy con đã được liên kết trực tiếp với tài khoản Phụ huynh. Dữ liệu GPS & thời gian dùng máy sẽ được đồng bộ ngay lập tức.',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () {
                Navigator.pop(dialogCtx);
                setState(() => _isProcessing = false);
              },
              child: const Text('ĐÃ HÌNH THÀNH LIÊN KẾT'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QUÉT MÃ QR KHÓA/GHÉP NỐI'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt), text: 'Quét QR Máy Con'),
            Tab(icon: Icon(Icons.qr_code_2), text: 'Tạo Mã QR Máy Bố Mẹ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Real Camera QR Scanner
          Column(
            children: [
              Expanded(
                child: _isCheckingPermission
                    ? const Center(child: CircularProgressIndicator())
                    : !_hasCameraPermission
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.camera_enhance, size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Cần cấp quyền Camera để quét mã QR thực tế',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                                    onPressed: _requestCameraPermission,
                                    icon: const Icon(Icons.security),
                                    label: const Text('CẤP QUYỀN CAMERA'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              MobileScanner(
                                controller: _scannerController,
                                onDetect: _onQrDetected,
                              ),

                              // Scanner Framing Overlay
                              Container(
                                width: 240,
                                height: 240,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.amber, width: 4),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 10)],
                                ),
                              ),

                              Positioned(
                                top: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.center_focus_strong, color: Colors.amber, size: 18),
                                      SizedBox(width: 8),
                                      Text('Hướng camera vào mã QR ghép nối', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),

                              Positioned(
                                bottom: 16,
                                child: Row(
                                  children: [
                                    IconButton(
                                      color: Colors.white,
                                      icon: const Icon(Icons.flash_on),
                                      onPressed: () => _scannerController.toggleTorch(),
                                    ),
                                    const SizedBox(width: 20),
                                    IconButton(
                                      color: Colors.white,
                                      icon: const Icon(Icons.cameraswitch),
                                      onPressed: () => _scannerController.switchCamera(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),

              // Bottom Input Bar
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Mã ghép nối (nhập tay nếu cần)',
                        prefixIcon: Icon(Icons.pin),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final code = _codeController.text.trim();
                          if (code.isNotEmpty) {
                            _processPairingCode(code);
                          }
                        },
                        icon: const Icon(Icons.link),
                        label: const Text('XÁC NHẬN GHÉP NỐI'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tab 2: Generator
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Mã QR Ghép Nối Thiết Bị Phụ Huynh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Dùng camera trên máy của trẻ quét mã bên dưới để liên kết tức thì với tài khoản Phụ huynh.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),

                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: QrImageView(
                      data: 'PARENT_PAIR_8899',
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Chip(
                  avatar: const Icon(Icons.key, color: Colors.purple),
                  label: const Text('Mã liên kết: PARENT_PAIR_8899', style: TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.purple.shade50,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
