import 'package:flutter/material.dart';
import '../../models/child_profile_model.dart';
import '../../models/app_rule_model.dart';
import '../../services/api_service.dart';

class ChildCrudScreen extends StatefulWidget {
  const ChildCrudScreen({super.key});

  @override
  State<ChildCrudScreen> createState() => _ChildCrudScreenState();
}

class _ChildCrudScreenState extends State<ChildCrudScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ChildProfileModel> _children = [];
  List<AppRuleModel> _rules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  void _loadData() async {
    setState(() => _isLoading = true);
    final kids = await ApiService.getChildren();
    final rules = await ApiService.getAppRules('child_1');
    if (mounted) {
      setState(() {
        _children = kids;
        _rules = rules;
        _isLoading = false;
      });
    }
  }

  void _showAddEditChildDialog([ChildProfileModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.childName ?? '');
    final ageCtrl = TextEditingController(text: existing?.age.toString() ?? '10');
    final deviceCtrl = TextEditingController(text: existing?.deviceModel ?? 'Samsung Galaxy Tab');
    final limitCtrl = TextEditingController(text: existing?.dailyMaxMinutes.toString() ?? '120');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(existing == null ? 'Thêm Hồ Sơ Trẻ Em Mới' : 'Cập Nhật Hồ Sơ Trẻ Em'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Tên của trẻ')),
              const SizedBox(height: 10),
              TextField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tuổi')),
              const SizedBox(height: 10),
              TextField(controller: deviceCtrl, decoration: const InputDecoration(labelText: 'Tên thiết bị (VD: iPad, Galaxy Tab)')),
              const SizedBox(height: 10),
              TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Giới hạn dùng/ngày (phút)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final messenger = ScaffoldMessenger.of(context);
              final newModel = ChildProfileModel(
                id: existing?.id ?? 'child_${DateTime.now().millisecondsSinceEpoch}',
                parentId: 'parent_101',
                childName: nameCtrl.text.trim(),
                age: int.tryParse(ageCtrl.text) ?? 10,
                deviceModel: deviceCtrl.text.trim(),
                dailyMaxMinutes: int.tryParse(limitCtrl.text) ?? 120,
                usedMinutes: existing?.usedMinutes ?? 30,
                pairingCode: existing?.pairingCode ?? 'KID-${(1000 + _children.length * 55)}',
              );

              if (existing == null) {
                await ApiService.addChild(newModel);
              } else {
                await ApiService.updateChild(newModel);
              }

              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
              if (mounted) {
                _loadData();
                messenger.showSnackBar(
                  SnackBar(content: Text(existing == null ? 'Thêm thành công!' : 'Cập nhật thành công!')),
                );
              }
            },
            child: Text(existing == null ? 'TẠO MỚI' : 'LƯU'),
          ),
        ],
      ),
    );
  }

  void _deleteChild(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    await ApiService.deleteChild(id);
    _loadData();
    if (mounted) {
      messenger.showSnackBar(const SnackBar(content: Text('Đã xóa hồ sơ trẻ em!')));
    }
  }

  void _showAddEditRuleDialog([AppRuleModel? existing]) {
    final appNameCtrl = TextEditingController(text: existing?.appName ?? '');
    final limitCtrl = TextEditingController(text: existing?.timeLimitMinutes.toString() ?? '60');
    bool isBlocked = existing?.isBlocked ?? false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Thêm Quy Tắc App' : 'Sửa Quy Tắc App'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: appNameCtrl, decoration: const InputDecoration(labelText: 'Tên ứng dụng (VD: TikTok, YouTube)')),
              const SizedBox(height: 10),
              TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Giới hạn (phút/ngày)')),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Chặn ứng dụng hoàn toàn'),
                value: isBlocked,
                onChanged: (val) => setDialogState(() => isBlocked = val),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                if (appNameCtrl.text.isEmpty) return;
                final messenger = ScaffoldMessenger.of(context);
                final rule = AppRuleModel(
                  id: existing?.id ?? 'rule_${DateTime.now().millisecondsSinceEpoch}',
                  childId: 'child_1',
                  appName: appNameCtrl.text.trim(),
                  packageName: 'com.app.${appNameCtrl.text.toLowerCase()}',
                  timeLimitMinutes: int.tryParse(limitCtrl.text) ?? 60,
                  isBlocked: isBlocked,
                );
                await ApiService.addOrUpdateAppRule(rule);
                if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                if (mounted) {
                  _loadData();
                  messenger.showSnackBar(const SnackBar(content: Text('Đã lưu quy tắc app!')));
                }
              },
              child: const Text('LƯU QUY TẮC'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QUẢN LÝ CRUD '),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.child_care), text: 'Hồ Sơ Trẻ Em'),
            Tab(icon: Icon(Icons.apps_outage), text: 'Quy Tắc Chặn App'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Danh sách hồ sơ trẻ em', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                            onPressed: () => _showAddEditChildDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm Bé Mới'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _children.length,
                          itemBuilder: (context, index) {
                            final child = _children[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo.shade100,
                                  child: Text(child.childName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                                ),
                                title: Text('${child.childName} (${child.age} tuổi)', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Thiết bị: ${child.deviceModel}\nGiới hạn: ${child.dailyMaxMinutes} phút/ngày • Code: ${child.pairingCode}'),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _showAddEditChildDialog(child),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteChild(child.id),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Quy tắc thời gian & Chặn App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                            onPressed: () => _showAddEditRuleDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Thêm Quy Tắc'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _rules.length,
                          itemBuilder: (context, index) {
                            final rule = _rules[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: rule.isBlocked ? Colors.red.shade100 : Colors.green.shade100,
                                  child: Icon(
                                    rule.isBlocked ? Icons.block : Icons.timer,
                                    color: rule.isBlocked ? Colors.red : Colors.green,
                                  ),
                                ),
                                title: Text(rule.appName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(rule.isBlocked
                                    ? 'Trạng thái: ĐÃ CHẶN HOÀN TOÀN'
                                    : 'Giới hạn: ${rule.timeLimitMinutes} phút/ngày • Đã dùng: ${rule.usedMinutes} phút'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await ApiService.deleteAppRule(rule.id);
                                    _loadData();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
