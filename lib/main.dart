import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'core/services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  await SettingsService().load(); // pre-load so providers get cached data

  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      title: 'Media Downloader',
      minimumSize: Size(1000, 700),
    ),
        () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.center();
    },
  );

  runApp(
    const ProviderScope(
      child: MediaDownloaderApp(),
    ),
  );
}