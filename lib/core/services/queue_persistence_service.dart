import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../models/download_task.dart';

class QueuePersistenceService {
  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/queue.json');
  }

  Future<List<DownloadTask>> load() async {
    try {
      final f = await _file;
      if (await f.exists()) {
        final content = await f.readAsString();
        final list = json.decode(content) as List;
        return list
            .map((e) => DownloadTask.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<void> save(List<DownloadTask> tasks) async {
    final persistable =
        tasks.where((t) => t.status == DownloadTaskStatus.queued || t.status == DownloadTaskStatus.paused).toList();
    final f = await _file;
    final data = json.encode(persistable.map((t) => t.toJson()).toList());
    await f.writeAsString(data);
  }

  Future<void> clear() async {
    final f = await _file;
    if (await f.exists()) {
      await f.delete();
    }
  }
}
