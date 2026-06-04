import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      title: 'Media Downloader',
      center: true,
      minimumSize: Size(1000, 700),
    ),
        () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );

  runApp(
    const ProviderScope(
      child: MediaDownloaderApp(),
    ),
  );
}