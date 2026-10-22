import 'package:flutter/material.dart';
import '../../models/noise_log_model.dart';
import '../../services/noise_meter_service.dart';

class NoiseDetectorScreen extends StatefulWidget {
  const NoiseDetectorScreen({super.key});

  @override
  State<NoiseDetectorScreen> createState() => _NoiseDetectorScreenState();
}

class _NoiseDetectorScreenState extends State<NoiseDetectorScreen> {
  @override
  void initState() {
    super.initState();
    NoiseMeterService.instance.startMonitoring();
  }

  @override
  void dispose() {
    NoiseMeterService.instance.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ĐO TIẾNG ỒN MICRO THẬT'),
        backgroundColor: Colors.orange.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Khởi động lại Microphone',
            onPressed: () => NoiseMeterService.instance.startMonitoring(),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: NoiseMeterService.instance,
        builder: (context, _) {
          final noiseService = NoiseMeterService.instance;
          final db = noiseService.currentDecibels;
          final status = noiseService.currentStatus;
          final logs = noiseService.historyLogs;

          Color statusColor = Colors.green;
          if (status == NoiseLevelStatus.warning) statusColor = Colors.orange;
          if (status == NoiseLevelStatus.danger) statusColor = Colors.red;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (!noiseService.hasMicrophonePermission)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.mic_off, color: Colors.red, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Cần cấp quyền Microphone để đo âm thanh thực tế',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => noiseService.startMonitoring(),
                          icon: const Icon(Icons.security),
                          label: const Text('CẤP QUYỀN MICROPHONE'),
                        ),
                      ],
                    ),
                  ),

                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.1),
                    border: Border.all(color: statusColor, width: 8),
                    boxShadow: [
                      BoxShadow(color: statusColor.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        noiseService.isMonitoring ? Icons.mic_rounded : Icons.mic_off_rounded,
                        size: 36,
                        color: statusColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        db.toStringAsFixed(1),
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                      const Text('dB (Decibels Thật)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        status == NoiseLevelStatus.danger ? Icons.volume_up : Icons.volume_down,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        NoiseLogModel.statusToText(status),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  '🎙️ Cảm biến Microphone phần cứng đang lắng nghe trực tiếp môi trường xung quanh (Thử vỗ tay hoặc nói chuyện gần điện thoại).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                if (db > 65.0) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: Colors.red.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'CẢNH BÁO THÍNH GIÁC: Môi trường vượt quá 65dB! Tiếng ồn lớn thu từ Mic gây phân tâm cho trẻ.',
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('📊 Lịch sử đo tiếng ồn Mic thật', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${logs.length} bản ghi', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final isHigh = log.decibels > 65.0;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isHigh ? Colors.red.shade100 : Colors.green.shade100,
                          child: Text(
                            log.decibels.toStringAsFixed(0),
                            style: TextStyle(fontWeight: FontWeight.bold, color: isHigh ? Colors.red : Colors.green),
                          ),
                        ),
                        title: Text('${log.decibels.toStringAsFixed(1)} dB • ${log.note}'),
                        subtitle: Text('Thời gian: ${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}'),
                        trailing: Icon(
                          isHigh ? Icons.error_outline : Icons.check_circle_outline,
                          color: isHigh ? Colors.red : Colors.green,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
