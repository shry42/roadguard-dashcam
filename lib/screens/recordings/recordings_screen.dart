import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/recordings_repository.dart';

class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<RecordingItem> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _all = await RecordingsRepository.instance.listRecordings();
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordings'),
        automaticallyImplyLeading: !widget.embedded,
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'All'), Tab(text: 'Events'), Tab(text: 'Saved')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_all),
                _buildList(_all.where((r) => r.title.toLowerCase().contains('event')).toList()),
                _buildList(_all),
              ],
            ),
    );
  }

  Widget _buildList(List<RecordingItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off_outlined, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('No recordings yet', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 4),
            const Text('Record from the Live tab', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RecordingCard(
              title: item.title,
              time: item.timeLabel,
              duration: item.durationLabel,
              size: item.sizeLabel,
              isEvent: item.title.toLowerCase().contains('event'),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.recordingDetail,
                arguments: item.file,
              ),
              onDelete: () async {
                await RecordingsRepository.instance.deleteRecording(item.file);
                await _load();
              },
            ),
          );
        },
      ),
    );
  }
}

class _RecordingCard extends StatelessWidget {
  const _RecordingCard({
    required this.title,
    required this.time,
    required this.duration,
    required this.size,
    required this.isEvent,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String time;
  final String duration;
  final String size;
  final bool isEvent;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 88,
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                    ),
                    child: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 40),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.overlay,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(duration, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('$time · $size', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
