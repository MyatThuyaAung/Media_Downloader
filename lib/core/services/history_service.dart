import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../models/download_task.dart';

class HistoryService {
  List<DownloadTask> _cache = const [];
  bool _loaded = false;

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/history.json');
  }

  Future<List<DownloadTask>> load() async {
    if (_loaded) return _cache;
    try {
      final f = await _file;
      if (await f.exists()) {
        final content = await f.readAsString();
        final list = json.decode(content) as List;
        _cache = list
            .map((e) => DownloadTask.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    _loaded = true;
    return _cache;
  }

  Future<void> save(List<DownloadTask> tasks) async {
    _cache = tasks;
    final f = await _file;
    final data = json.encode(tasks.map((t) => t.toJson()).toList());
    await f.writeAsString(data);
  }
}
