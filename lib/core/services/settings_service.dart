import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class SettingsService {
  Map<String, dynamic> _cache = {};
  bool _loaded = false;

  Future<File> get _file async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/settings.json');
  }

  Future<Map<String, dynamic>> load() async {
    if (_loaded) return _cache;
    try {
      final f = await _file;
      if (await f.exists()) {
        final content = await f.readAsString();
        _cache = Map<String, dynamic>.from(json.decode(content) as Map);
      }
    } catch (_) {}
    _loaded = true;
    return _cache;
  }

  Future<void> save(Map<String, dynamic> data) async {
    _cache = data;
    final f = await _file;
    await f.writeAsString(json.encode(data));
  }

  Future<String?> getOutputDirectory() async {
    final data = await load();
    return data['outputDirectory'] as String?;
  }

  Future<String?> getDefaultCookiesBrowser() async {
    final data = await load();
    return data['defaultCookiesBrowser'] as String?;
  }

  Future<void> setOutputDirectory(String? path) async {
    final data = await load();
    data['outputDirectory'] = path;
    await save(data);
  }

  Future<void> setDefaultCookiesBrowser(String? value) async {
    final data = await load();
    data['defaultCookiesBrowser'] = value;
    await save(data);
  }
}
