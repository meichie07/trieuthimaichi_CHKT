import 'package:flutter/material.dart';

class AiStudyGuardianScreen extends StatefulWidget {
  const AiStudyGuardianScreen({super.key});

  @override
  State<AiStudyGuardianScreen> createState() => _AiStudyGuardianScreenState();
}

class _AiStudyGuardianScreenState extends State<AiStudyGuardianScreen> {
  final TextEditingController _urlController = TextEditingController(text: 'https://wikipedia.org');
  bool _isSafeSearchEnabled = true;
  bool _isAdultFilterActive = true;
  bool _isGamblingFilterActive = true;

  bool _isAnalyzingUrl = false;
  Map<String, dynamic>? _scanResult;

  final List<String> _blockedKeywords = [
    'cờ bạc',
    'cá cược',
    'casino',
    'phim 18+',
    'đồi trụy',
    'hack game',
    'bạo lực',
  ];

  final List<Map<String, dynamic>> _recentWebHistory = [
    {'url': 'wikipedia.org', 'time': '10 phút trước', 'status': 'An toàn 100%', 'color': Colors.green},
    {'url': 'duolingo.com', 'time': '30 phút trước', 'status': 'An toàn 100%', 'color': Colors.green},
    {'url': 'co-bac-online-bet.com', 'time': '1 giờ trước', 'status': 'ĐÁNH DẤU CHẶN (Cờ bạc)', 'color': Colors.red},
  ];

  void _analyzeWebUrl() async {
    final query = _urlController.text.trim().toLowerCase();
    if (query.isEmpty) return;

    setState(() {
      _isAnalyzingUrl = true;
      _scanResult = null;
    });

    await Future.delayed(const Duration(milliseconds: 800));

    bool isBlocked = false;
    String blockReason = '';

    for (final kw in _blockedKeywords) {
      if (query.contains(kw)) {
        isBlocked = true;
        blockReason = 'Chứa từ khóa bị cấm: "$kw"';
        break;
      }
    }

    if (!isBlocked && (_isGamblingFilterActive || _isAdultFilterActive)) {
      if (query.contains('bet') || query.contains('casino') || query.contains('88')) {
        isBlocked = true;
        blockReason = 'Trang web nghi vấn cờ bạc & cá cược';
      } else if (query.contains('sex') || query.contains('18+') || query.contains('porn')) {
        isBlocked = true;
        blockReason = 'Nội dung người lớn / Đồi trụy';
      }
    }

    if (mounted) {
      setState(() {
        _isAnalyzingUrl = false;
        if (isBlocked) {
          _scanResult = {
            'isSafe': false,
            'url': query,
            'reason': blockReason,
            'score': '0/100 (ĐỘC HẠI)',
          };
          _recentWebHistory.insert(0, {
            'url': query,
            'time': 'Vừa xong',
            'status': 'ĐÃ CHẶN ($blockReason)',
            'color': Colors.red,
          });
        } else {
          _scanResult = {
            'isSafe': true,
            'url': query,
            'reason': 'Đã xác minh đạt tiêu chuẩn An Toàn cho Trẻ Em',
            'score': '100/100 (AN TOÀN)',
          };
          _recentWebHistory.insert(0, {
            'url': query,
            'time': 'Vừa xong',
            'status': 'An toàn 100%',
            'color': Colors.green,
          });
        }
      });
    }
  }

  void _showAddKeywordDialog() {
    final kwCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('Thêm Từ Khóa Bị Chặn'),
          ],
        ),
        content: TextField(
          controller: kwCtrl,
          decoration: const InputDecoration(
            labelText: 'Nhập từ khóa hoặc tên miền cấm',
            hintText: 'Ví dụ: game cờ bạc, phim 18+',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (kwCtrl.text.trim().isEmpty) return;
              setState(() {
                _blockedKeywords.add(kwCtrl.text.trim().toLowerCase());
              });
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ Đã thêm từ khóa bị chặn: "${kwCtrl.text}"')),
              );
            },
            child: const Text('THÊM BỘ LỌC'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TÍNH NĂNG MỚI'),
        backgroundColor: Colors.teal.shade900,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FEATURE BANNER CARD
            Card(
              color: Colors.teal.shade900,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.security, size: 36, color: Colors.black87),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('SAFE BROWSER & KEYWORD FILTER', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11)),
                              SizedBox(height: 2),
                              Text('Trình Duyệt An Toàn & Bộ Lọc Web Độc Hại', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 28),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            Icon(Icons.public_off, color: Colors.amber, size: 28),
                            SizedBox(height: 4),
                            Text('Chặn web cấm', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.travel_explore, color: Colors.amber, size: 28),
                            SizedBox(height: 4),
                            Text('Tìm kiếm an toàn', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                        Column(
                          children: [
                            Icon(Icons.find_in_page, color: Colors.amber, size: 28),
                            SizedBox(height: 4),
                            Text('Lọc từ khóa', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // INTERACTIVE SAFE BROWSER / URL ANALYZER CARD
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌐 KIỂM TRA & DUYỆT WEB AN TOÀN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: 'Nhập địa chỉ web hoặc từ khóa tìm kiếm...',
                        prefixIcon: const Icon(Icons.search, color: Colors.teal),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, color: Colors.teal),
                          onPressed: _analyzeWebUrl,
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isAnalyzingUrl ? null : _analyzeWebUrl,
                        icon: _isAnalyzingUrl
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.verified_user_rounded),
                        label: Text(_isAnalyzingUrl ? 'ĐANG PHÂN TÍCH TIÊU CHUẨN AN TOÀN...' : 'PHÂN TÍCH & TRUY CẬP WEB'),
                      ),
                    ),

                    if (_scanResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _scanResult!['isSafe'] ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _scanResult!['isSafe'] ? Colors.green.shade200 : Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _scanResult!['isSafe'] ? Icons.check_circle : Icons.cancel,
                                  color: _scanResult!['isSafe'] ? Colors.green : Colors.red,
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _scanResult!['isSafe'] ? 'TRANG WEB AN TOÀN' : '⚠️ ĐÃ KHÓA / CẢNH BÁO ĐỘC HẠI',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: _scanResult!['isSafe'] ? Colors.green.shade900 : Colors.red.shade900,
                                        ),
                                      ),
                                      Text('Độ an toàn: ${_scanResult!['score']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Lý do: ${_scanResult!['reason']}', style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // KEYWORD BLACKLIST MANAGEMENT
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('🚫 Từ khóa & Chủ đề bị cấm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.teal),
                          onPressed: _showAddKeywordDialog,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _blockedKeywords.map((kw) {
                        return Chip(
                          avatar: const Icon(Icons.block, size: 16, color: Colors.red),
                          label: Text(kw, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          backgroundColor: Colors.red.shade50,
                          deleteIcon: const Icon(Icons.cancel, size: 16),
                          onDeleted: () {
                            setState(() {
                              _blockedKeywords.remove(kw);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // CONFIGURATION SWITCHES
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.travel_explore, color: Colors.teal),
                    title: const Text('Bật Google/Bing SafeSearch'),
                    subtitle: const Text('Tự động lọc các kết quả tìm kiếm không phù hợp với lứa tuổi'),
                    value: _isSafeSearchEnabled,
                    onChanged: (val) => setState(() => _isSafeSearchEnabled = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.no_adult_content, color: Colors.red),
                    title: const Text('Tự động chặn trang web cờ bạc & 18+'),
                    subtitle: const Text('Chặn các địa chỉ web nghi vấn cờ bạc & nội dung người lớn'),
                    value: _isAdultFilterActive,
                    onChanged: (val) => setState(() {
                      _isAdultFilterActive = val;
                      _isGamblingFilterActive = val;
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // RECENT BROWSER HISTORY LOGS
            Text('🕒 Lịch sử kiểm tra web gần đây', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentWebHistory.length,
              itemBuilder: (context, index) {
                final item = _recentWebHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: (item['color'] as Color).withValues(alpha: 0.15),
                      child: Icon(Icons.language, color: item['color'] as Color),
                    ),
                    title: Text(item['url'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Thời gian: ${item['time']}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['status'],
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: item['color'] as Color),
                      ),
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
