import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class RecordingItem {
  const RecordingItem({
    required this.file,
    required this.title,
    required this.timeLabel,
    required this.durationLabel,
    required this.sizeLabel,
    required this.createdAt,
  });

  final File file;
  final String title;
  final String timeLabel;
  final String durationLabel;
  final String sizeLabel;
  final DateTime createdAt;
}

class RecordingsRepository {
  RecordingsRepository._();
  static final RecordingsRepository instance = RecordingsRepository._();

  Future<Directory> get recordingsDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'recordings'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> newRecordingPath() async {
    final dir = await recordingsDir;
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    return p.join(dir.path, 'trip_$stamp.mp4');
  }

  Future<List<RecordingItem>> listRecordings() async {
    final dir = await recordingsDir;
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.mp4'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return files.map((file) {
      final stat = file.statSync();
      final created = stat.modified;
      final bytes = stat.size;
      return RecordingItem(
        file: file,
        title: _titleFromFile(file.path),
        timeLabel: DateFormat('h:mm a · MMM d').format(created),
        durationLabel: '—',
        sizeLabel: _formatBytes(bytes),
        createdAt: created,
      );
    }).toList();
  }

  String _titleFromFile(String path) {
    final name = p.basenameWithoutExtension(path);
    if (name.startsWith('trip_')) {
      return 'Trip ${name.replaceFirst('trip_', '').replaceAll('_', ' ')}';
    }
    return name;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  Future<void> deleteRecording(File file) async {
    if (file.existsSync()) await file.delete();
  }
}
