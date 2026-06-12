import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/download_task.dart';
import '../../models/download_progress.dart';
import '../../models/video_format.dart';
import '../../core/services/download_service.dart';
import '../../core/services/queue_persistence_service.dart';
import '../history/history_provider.dart';

final downloadQueueProvider =
    StateNotifierProvider<DownloadQueueNotifier, DownloadQueueState>(
  (ref) => DownloadQueueNotifier(ref),
);

final _queuePersistence = QueuePersistenceService();

class DownloadQueueState {
  final List<DownloadTask> tasks;

  const DownloadQueueState({this.tasks = const []});

  DownloadQueueState copyWith({List<DownloadTask>? tasks}) {
    return DownloadQueueState(tasks: tasks ?? this.tasks);
  }
}

class DownloadQueueNotifier extends StateNotifier<DownloadQueueState> {
  DownloadQueueNotifier(this._ref) : super(const DownloadQueueState()) {
    _init();
  }

  final Ref _ref;

  /// All active download services, keyed by task ID.
  /// A task may be in network-download phase or post-processing (muxing) phase.
  final Map<String, DownloadService> _services = {};

  /// The task currently in the network-download phase (0–100%).
  /// Only one task can be in this phase at a time.
  String? _networkTaskId;

  /// Tasks whose network download has finished (>=100%) but whose
  /// yt-dlp process is still running (muxing/converting with ffmpeg).
  final Set<String> _processingTaskIds = {};



  Future<void> _init() async {
    final saved = await _queuePersistence.load();
    if (saved.isNotEmpty) {
      state = state.copyWith(tasks: saved);
    }
  }

  Future<void> _persistQueue() async {
    await _queuePersistence.save(state.tasks);
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  void addTask({
    required String url,
    required String title,
    String? thumbnailUrl,
    String? uploader,
    required VideoFormat format,
    String? cookiesBrowser,
    String? subtitleLang,
    String? outputDirectory,
    int duration = 0,
    int? viewCount,
  }) {
    var safeTitle =
        title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (outputDirectory != null) {
      try {
        final dir = Directory(outputDirectory);
        if (dir.existsSync()) {
          int suffix = 0;
          String candidate;
          do {
            candidate = suffix == 0 ? safeTitle : '${safeTitle}_$suffix';
            suffix++;
          } while (dir.listSync().any((f) {
            final name = f.path.replaceAll('\\', '/').split('/').last;
            return name.startsWith('$candidate.');
          }));
          safeTitle = candidate;
        }
      } catch (_) {
        // If directory listing fails, proceed without suffix
      }
    }
    final outputPath = outputDirectory != null
        ? '$outputDirectory/$safeTitle.%(ext)s'
        : null;
    final task = DownloadTask(
      id: const Uuid().v4(),
      url: url,
      title: title,
      thumbnailUrl: thumbnailUrl,
      uploader: uploader,
      format: format,
      cookiesBrowser: cookiesBrowser,
      subtitleLang: subtitleLang,
      outputPath: outputPath,
      duration: duration,
      viewCount: viewCount,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(tasks: [...state.tasks, task]);
    _persistQueue();
    _processNext();
  }

  // ── Queue processing ──────────────────────────────────────────────────────

  /// Starts the next queued task if no task is in the network-download phase.
  /// Post-processing (muxing) tasks do not block the queue.
  void _processNext() {
    if (_networkTaskId != null) return;

    final index =
        state.tasks.indexWhere((t) => t.status == DownloadTaskStatus.queued);
    if (index == -1) return;

    final task = state.tasks[index];

    // Double-check: skip if this task is already tracked elsewhere
    if (_processingTaskIds.contains(task.id) || _services.containsKey(task.id)) {
      return;
    }

    _networkTaskId = task.id;
    _updateTask(task.id, status: DownloadTaskStatus.downloading);
    _startDownload(task);
  }

  Future<String> _generateOutputPath(String title) async {
    final downloadsDir = await getDownloadsDirectory();
    final outputDir = downloadsDir?.path ?? '.';
    final safeTitle =
        title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return '$outputDir/$safeTitle.%(ext)s';
  }

  Future<void> _startDownload(DownloadTask task, {bool resume = false}) async {
    // ── Strict guard: never spawn a second process for the same task ──
    if (task.status != DownloadTaskStatus.queued && !resume) return;
    if (_networkTaskId != null && _networkTaskId != task.id) return;
    if (_services.containsKey(task.id)) return;
    if (_processingTaskIds.contains(task.id)) return;

    try {
      // Mark as downloading immediately (redundant if _processNext already did it,
      // but acts as a second barrier for direct calls)
      _updateTask(task.id, status: DownloadTaskStatus.downloading);

      final outputPath =
          task.outputPath ?? await _generateOutputPath(task.title);

      if (task.outputPath == null) {
        _updateTaskOutputPath(task.id, outputPath);
      }

      // Immediate phase feedback before yt-dlp handshake
      _updateTask(
        task.id,
        progress: DownloadProgress.phase(
          resume ? 'Resuming download...' : 'Starting download...',
        ),
      );

      final service = DownloadService();
      _services[task.id] = service;

      // Append best audio if the selected format is video-only
      final ac = task.format.acodec;
      final formatId = (ac == null || ac == 'none')
          ? '${task.format.formatId}+bestaudio'
          : task.format.formatId;

      final stream = service.download(
        taskId: task.id,
        url: task.url,
        formatId: formatId,
        outputPath: outputPath,
        cookiesBrowser: task.cookiesBrowser,
        resume: resume,
        subtitleLang: task.subtitleLang,
      );

      stream.listen(
        (progress) {
          _onProgress(task.id, progress);
        },
        onError: (Object e) {
          _failTask(task.id, e.toString());
        },
        onDone: () {
          try {
            final t = state.tasks.firstWhere((t) => t.id == task.id);
            if (t.status == DownloadTaskStatus.done ||
                t.status == DownloadTaskStatus.error) {
              return;
            }
            _failTask(task.id, 'Download stream ended unexpectedly');
          } catch (_) {}
        },
      );
    } catch (e) {
      // Only fail if task is still alive and hasn't already been terminated
      try {
        final t = state.tasks.firstWhere((t) => t.id == task.id);
        if (t.status != DownloadTaskStatus.done &&
            t.status != DownloadTaskStatus.error) {
          _failTask(task.id, e.toString());
        }
      } catch (_) {}
    }
  }

  /// Handles each progress event from a running download.
  void _onProgress(String taskId, DownloadProgress progress) {
    // Phase-only updates (percent=0, no isDone): merge into existing progress
    // rather than overwriting, so the progress bar doesn't disappear mid-stream.
    if (progress.phase != null && progress.percent == 0 && !progress.isDone) {
      final existing = state.tasks.firstWhere((t) => t.id == taskId).progress;
      if (existing != null && existing.percent > 0 && !existing.isDone) {
        // Skip misleading "Initializing..." during post-processing phase
        if (!_processingTaskIds.contains(taskId) ||
            progress.phase != 'Initializing...') {
          _updateTask(
              taskId, progress: existing.copyWith(phase: progress.phase));
        }
      } else {
        _updateTask(taskId, progress: progress);
      }
      return;
    }

    // Normal numeric progress update
    _updateTask(taskId, progress: progress);

    if (progress.isDone) {
      _finishTask(taskId);
      return;
    }

    // Network download milestone: first time reaching >= 100%
    if (_isNetworkPhase(taskId) && progress.percent >= 100) {
      _onDownloadComplete(taskId);
    }
  }

  /// Returns true if [taskId] is still in the network-download phase
  /// (has not yet reached 100% or triggered a phase transition).
  bool _isNetworkPhase(String taskId) =>
      taskId == _networkTaskId && !_processingTaskIds.contains(taskId);

  /// Called when the network download phase finishes (100% reached,
  /// yt-dlp has all bytes on disk and starts post-processing).
  ///
  /// Moves the task to the post-processing (muxing) phase and immediately
  /// starts the next queued download. The progress bar stays pinned at 100%
  /// with the actual phase (e.g. "Downloading Audio") preserved.
  void _onDownloadComplete(String taskId) {
    _processingTaskIds.add(taskId);
    _networkTaskId = null;

    // Unblock the queue — next file starts NOW,
    // while this task continues muxing in its own process
    _processNext();
  }

  /// Called when yt-dlp exits cleanly after both download and post-processing.
  void _finishTask(String taskId) {
    _services.remove(taskId);
    _processingTaskIds.remove(taskId);
    if (taskId == _networkTaskId) _networkTaskId = null;

    _updateTask(taskId,
        status: DownloadTaskStatus.done,
        progress: DownloadProgress.done,
        completedAt: DateTime.now());

    // Save to history
    try {
      final task = state.tasks.firstWhere((t) => t.id == taskId);
      _ref.read(historyProvider.notifier).addEntry(task);
    } catch (_) {}

    _persistQueue();
    _processNext();
  }

  // ── Pause / Resume ───────────────────────────────────────────────────────

  void pauseTask(String taskId) {
    _cancelService(taskId);
    _processingTaskIds.remove(taskId);
    if (taskId == _networkTaskId) _networkTaskId = null;

    _updateTask(taskId, status: DownloadTaskStatus.paused);
    _persistQueue();
    _processNext();
  }

  void resumeTask(String taskId) {
    _updateTask(taskId,
        status: DownloadTaskStatus.queued, errorMessage: null);
    _persistQueue();
    _processNext();
  }

  void pauseAll() {
    for (final id in _services.keys.toList()) {
      _cancelService(id);
      _processingTaskIds.remove(id);
    }
    _networkTaskId = null;

    state = state.copyWith(
      tasks: state.tasks.map((t) {
        if (t.status == DownloadTaskStatus.downloading ||
            t.status == DownloadTaskStatus.queued) {
          return t.copyWith(status: DownloadTaskStatus.paused);
        }
        return t;
      }).toList(),
    );
    _persistQueue();
  }

  void resumeAll() {
    state = state.copyWith(
      tasks: state.tasks.map((t) {
        if (t.status == DownloadTaskStatus.paused) {
          return t.copyWith(status: DownloadTaskStatus.queued);
        }
        return t;
      }).toList(),
    );
    _persistQueue();
    _processNext();
  }

  // ── Cancel ───────────────────────────────────────────────────────────────

  void cancelActive() {
    if (_networkTaskId != null) {
      cancelTask(_networkTaskId!);
    } else if (_processingTaskIds.isNotEmpty) {
      cancelTask(_processingTaskIds.first);
    }
  }

  void cancelTask(String taskId) {
    final task = state.tasks.firstWhere((t) => t.id == taskId);

    if (task.status == DownloadTaskStatus.downloading ||
        _processingTaskIds.contains(taskId)) {
      _cancelService(taskId);
      _processingTaskIds.remove(taskId);
      if (taskId == _networkTaskId) _networkTaskId = null;

      _updateTask(task.id,
          status: DownloadTaskStatus.error, errorMessage: 'Cancelled');
      _processNext();
    } else if (task.status == DownloadTaskStatus.queued ||
        task.status == DownloadTaskStatus.paused) {
      _updateTask(task.id,
          status: DownloadTaskStatus.error, errorMessage: 'Cancelled');
    }
    _persistQueue();
  }

  // ── Misc ─────────────────────────────────────────────────────────────────

  void removeTask(String taskId) {
    _cancelService(taskId);
    _processingTaskIds.remove(taskId);
    if (taskId == _networkTaskId) _networkTaskId = null;

    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != taskId).toList(),
    );
    _persistQueue();
    _processNext();
  }

  void clearAllExceptInProgress() {
    state = state.copyWith(
      tasks: state.tasks
          .where((t) =>
              t.status == DownloadTaskStatus.queued ||
              t.status == DownloadTaskStatus.downloading ||
              t.status == DownloadTaskStatus.paused)
          .toList(),
    );
    _persistQueue();
  }

  // ── Internal helpers ─────────────────────────────────────────────────────

  void _cancelService(String taskId) {
    _services[taskId]?.cancel(taskId);
    _services.remove(taskId);
  }

  void _updateTask(
    String taskId, {
    DownloadTaskStatus? status,
    DownloadProgress? progress,
    String? errorMessage,
    DateTime? completedAt,
  }) {
    state = state.copyWith(
      tasks: state.tasks.map((t) {
        if (t.id != taskId) return t;
        return t.copyWith(
          status: status,
          progress: progress,
          errorMessage: errorMessage,
          completedAt: completedAt,
        );
      }).toList(),
    );
  }

  void _updateTaskOutputPath(String taskId, String? outputPath) {
    state = state.copyWith(
      tasks: state.tasks.map((t) {
        if (t.id != taskId) return t;
        return t.copyWith(outputPath: outputPath);
      }).toList(),
    );
  }

  void _failTask(String taskId, String error) {
    _cancelService(taskId);
    _processingTaskIds.remove(taskId);
    if (taskId == _networkTaskId) _networkTaskId = null;

    _updateTask(taskId, status: DownloadTaskStatus.error, errorMessage: error);
    _persistQueue();
    _processNext();
  }

  @override
  void dispose() {
    for (final id in _services.keys.toList()) {
      _cancelService(id);
    }
    super.dispose();
  }
}
