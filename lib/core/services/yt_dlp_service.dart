import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../models/playlist_info.dart';
import '../../models/video_info.dart';
import '../utils/binary_manager.dart';

class YtDlpService {
  final _binaryManager = BinaryManager.instance;

  Future<VideoInfo> fetchVideoInfo(String url, {String? cookiesBrowser}) async {
    final executable = await _binaryManager.ytDlpPath;

    final args = [
      '--dump-single-json',
      '--no-playlist',
      '--encoding', 'utf-8',
    ];

    try {
      final deno = await _binaryManager.denoPath;
      args.addAll(['--js-runtimes', 'deno:$deno']);
    } catch (e) {
      debugPrint('[yt_dlp_service] Deno not available, skipping JS runtime args: $e');
    }

    if (cookiesBrowser != null &&
        cookiesBrowser.isNotEmpty &&
        cookiesBrowser.toLowerCase() != 'none') {
      args.addAll(['--cookies-from-browser', cookiesBrowser.toLowerCase()]);
    }

    args.add(url);

    final process = await Process.start(executable, args);

    const decoder = Utf8Decoder(allowMalformed: true);
    final outputFuture = process.stdout.transform(decoder).join();
    final errorFuture = process.stderr.transform(decoder).join();

    final results = await Future.wait([outputFuture, errorFuture]);
    final output = results[0];
    final error = results[1];

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception(
        error.isNotEmpty ? error : 'yt-dlp exited with code $exitCode',
      );
    }

    final json = jsonDecode(output) as Map<String, dynamic>;
    debugPrint('[yt_dlp_service] subtitles keys: ${(json['subtitles'] as Map<String, dynamic>?)?.keys}');
    debugPrint('[yt_dlp_service] auto_captions keys: ${(json['automatic_captions'] as Map<String, dynamic>?)?.keys}');
    final info = VideoInfo.fromJson(json);
    debugPrint('[yt_dlp_service] subtitleLangs: ${info.subtitleLangs}');
    return info;
  }

  Future<PlaylistInfo> fetchPlaylistInfo(String url, {String? cookiesBrowser, int? maxEntries}) async {
    final executable = await _binaryManager.ytDlpPath;

    final args = [
      '--dump-single-json',
      '--flat-playlist',
      '--encoding', 'utf-8',
    ];

    if (maxEntries != null) {
      args.addAll(['--playlist-end', maxEntries.toString()]);
    }

    try {
      final deno = await _binaryManager.denoPath;
      args.addAll(['--js-runtimes', 'deno:$deno']);
    } catch (e) {
      debugPrint('[yt_dlp_service] Deno not available, skipping JS runtime args: $e');
    }

    if (cookiesBrowser != null &&
        cookiesBrowser.isNotEmpty &&
        cookiesBrowser.toLowerCase() != 'none') {
      args.addAll(['--cookies-from-browser', cookiesBrowser.toLowerCase()]);
    }

    args.add(url);

    final process = await Process.start(executable, args);

    const decoder = Utf8Decoder(allowMalformed: true);
    final outputFuture = process.stdout.transform(decoder).join();
    final errorFuture = process.stderr.transform(decoder).join();

    final results = await Future.wait([outputFuture, errorFuture]);
    final output = results[0];
    final error = results[1];

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      throw Exception(
        error.isNotEmpty ? error : 'yt-dlp exited with code $exitCode',
      );
    }

    final json = jsonDecode(output) as Map<String, dynamic>;
    return PlaylistInfo.fromJson(json);
  }
}
