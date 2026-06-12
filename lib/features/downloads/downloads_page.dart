import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/platform_utils.dart';
import '../../models/download_task.dart';
import '../../models/download_progress.dart';
import '../../widgets/app_sidebar.dart';
import 'download_queue_provider.dart';

enum _QueueTab { all, inProgress, finished, failed }

class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key});

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  _QueueTab _tab = _QueueTab.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(downloadQueueProvider);
    final notifier = ref.read(downloadQueueProvider.notifier);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final anyActive = state.tasks.any(
      (t) => t.status == DownloadTaskStatus.downloading ||
          t.status == DownloadTaskStatus.queued,
    );
    final anyPaused =
        state.tasks.any((t) => t.status == DownloadTaskStatus.paused);
    final activeCount =
        state.tasks.where((t) => t.status != DownloadTaskStatus.done).length;
    final hasClearable = state.tasks.any(
      (t) => t.status == DownloadTaskStatus.done ||
          t.status == DownloadTaskStatus.error,
    );

    final tasks = switch (_tab) {
      _QueueTab.inProgress => state.tasks
          .where((t) =>
              t.status == DownloadTaskStatus.queued ||
              t.status == DownloadTaskStatus.downloading ||
              t.status == DownloadTaskStatus.paused)
          .toList(),
      _QueueTab.finished => state.tasks
          .where((t) => t.status == DownloadTaskStatus.done)
          .toList(),
      _QueueTab.failed => state.tasks
          .where((t) => t.status == DownloadTaskStatus.error)
          .toList(),
      _QueueTab.all => state.tasks,
    };

    return Scaffold(
      backgroundColor: colors.surface,
      body: Row(
        children: [
          AppSidebar(colors: colors, queuedCount: activeCount),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  colors: colors,
                  hasActive: anyActive,
                  hasPaused: anyPaused,
                  onPauseAll: anyActive ? notifier.pauseAll : null,
                  onResumeAll: anyPaused ? notifier.resumeAll : null,
                  onClearAll: hasClearable ? notifier.clearAllExceptInProgress : null,
                ),
                // ── Tab bar ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colors.outlineVariant, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      _TabChip(
                        label: 'All',
                        count: state.tasks.length,
                        selected: _tab == _QueueTab.all,
                        colors: colors,
                        onTap: () => setState(() => _tab = _QueueTab.all),
                      ),
                      const SizedBox(width: 8),
                      _TabChip(
                        label: 'In-progress',
                        count: state.tasks
                            .where((t) =>
                                t.status == DownloadTaskStatus.queued ||
                                t.status == DownloadTaskStatus.downloading ||
                                t.status == DownloadTaskStatus.paused)
                            .length,
                        selected: _tab == _QueueTab.inProgress,
                        colors: colors,
                        onTap: () => setState(() => _tab = _QueueTab.inProgress),
                      ),
                      const SizedBox(width: 8),
                      _TabChip(
                        label: 'Finished',
                        count: state.tasks
                            .where((t) => t.status == DownloadTaskStatus.done)
                            .length,
                        selected: _tab == _QueueTab.finished,
                        colors: colors,
                        onTap: () => setState(() => _tab = _QueueTab.finished),
                      ),
                      const SizedBox(width: 8),
                      _TabChip(
                        label: 'Failed',
                        count: state.tasks
                            .where((t) => t.status == DownloadTaskStatus.error)
                            .length,
                        selected: _tab == _QueueTab.failed,
                        colors: colors,
                        onTap: () => setState(() => _tab = _QueueTab.failed),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: tasks.isEmpty
                      ? _EmptyState(colors: colors)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            final outputPath = task.outputPath;
                            return _TaskTile(
                              task: task,
                              colors: colors,
                              theme: theme,
                              onCancel: task.status ==
                                      DownloadTaskStatus.queued
                                  ? () => notifier.cancelTask(task.id)
                                  : null,
                              onPause: task.status ==
                                      DownloadTaskStatus.downloading
                                  ? () => notifier.pauseTask(task.id)
                                  : null,
                              onResume: task.status ==
                                      DownloadTaskStatus.paused
                                  ? () => notifier.resumeTask(task.id)
                                  : null,
                              onOpenFolder: task.status ==
                                                  DownloadTaskStatus.done &&
                                              outputPath != null
                                      ? () => PlatformUtils.openContainingFolder(outputPath)
                                      : null,
                              onRemove: task.status ==
                                              DownloadTaskStatus.done ||
                                          task.status ==
                                              DownloadTaskStatus.error
                                      ? () => notifier.removeTask(task.id)
                                      : null,
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.colors,
    required this.onTap,
  });
  final String label;
  final int count;
  final bool selected;
  final ColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? colors.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              color: selected ? colors.primary : colors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}



// ──────────────────────────────────────────────────────────────────────────────
// Top bar with global controls
// ──────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.colors,
    required this.hasActive,
    required this.hasPaused,
    this.onPauseAll,
    this.onResumeAll,
    this.onClearAll,
  });
  final ColorScheme colors;
  final bool hasActive;
  final bool hasPaused;
  final VoidCallback? onPauseAll;
  final VoidCallback? onResumeAll;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Downloads',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (onPauseAll != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: onPauseAll,
                icon: Icon(Icons.pause_rounded, size: 16, color: colors.primary),
                label: Text('Pause All',
                    style: TextStyle(fontSize: 12, color: colors.primary)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          if (onResumeAll != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: onResumeAll,
                icon: Icon(Icons.play_arrow_rounded,
                    size: 16, color: colors.primary),
                label: Text('Resume All',
                    style: TextStyle(fontSize: 12, color: colors.primary)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          if (onClearAll != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: onClearAll,
                icon: Icon(Icons.clear_all_rounded,
                    size: 16, color: colors.error),
                label: Text('Clear All',
                    style: TextStyle(fontSize: 12, color: colors.error)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          Icon(Icons.notifications_none_rounded,
              color: colors.onSurfaceVariant, size: 22),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 16,
            backgroundColor: colors.primaryContainer,
            child: Icon(Icons.person_rounded,
                color: colors.onPrimaryContainer, size: 18),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Empty state
// ──────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors});
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_outlined,
              size: 64, color: colors.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No downloads yet',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Go to the home page to add media to your download queue.',
            style: TextStyle(
              color: colors.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Task tile
// ──────────────────────────────────────────────────────────────────────────────

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.task,
    required this.colors,
    required this.theme,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRemove,
    this.onOpenFolder,
  });

  final DownloadTask task;
  final ColorScheme colors;
  final ThemeData theme;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onRemove;
  final VoidCallback? onOpenFolder;

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 100,
        height: 56,
        child: Stack(
          children: [
            if (task.thumbnailUrl != null && task.thumbnailUrl!.isNotEmpty)
              Image.network(
                task.thumbnailUrl!,
                width: 100,
                height: 56,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _ThumbPlaceholder(colors: colors, width: 100, height: 56),
                errorBuilder: (_, _, _) =>
                    _ThumbPlaceholder(colors: colors, width: 100, height: 56),
              )
            else
              _ThumbPlaceholder(colors: colors, width: 100, height: 56),
            if (task.duration > 0)
              Positioned(
                right: 3,
                bottom: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    _formatDuration(task.duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumbnail(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (task.uploader != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Row(
                                children: [
                                  _StatusIcon(status: task.status, colors: colors),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      task.uploader!,
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action buttons
                    if (onPause != null)
                      SizedBox(
                        height: 28,
                        child: OutlinedButton.icon(
                          onPressed: onPause,
                          icon: const Icon(Icons.pause_rounded, size: 12),
                          label: const Text('Pause', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primary,
                            side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (onResume != null)
                      SizedBox(
                        height: 28,
                        child: OutlinedButton.icon(
                          onPressed: onResume,
                          icon: const Icon(Icons.play_arrow_rounded, size: 12),
                          label: const Text('Resume', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.primary,
                            side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (onCancel != null)
                      SizedBox(
                        height: 28,
                        child: OutlinedButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(Icons.stop_rounded, size: 12),
                          label: const Text('Cancel', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.error,
                            side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (onOpenFolder != null)
                      SizedBox(
                        height: 28,
                        child: TextButton.icon(
                          onPressed: onOpenFolder,
                          icon: const Icon(Icons.folder_open_rounded, size: 12),
                          label: const Text('Folder', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (onRemove != null)
                      SizedBox(
                        height: 28,
                        child: TextButton.icon(
                          onPressed: onRemove,
                          icon: const Icon(Icons.close_rounded, size: 12),
                          label: const Text('Dismiss', style: TextStyle(fontSize: 11)),
                          style: TextButton.styleFrom(
                            foregroundColor: colors.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Phase / status label
                if (task.status == DownloadTaskStatus.downloading &&
                    task.progress != null &&
                    task.progress!.phase != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          task.progress!.phase!,
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Progress bar
                if (task.status == DownloadTaskStatus.downloading &&
                    task.progress != null &&
                    task.progress!.percent > 0) ...[
                  const SizedBox(height: 8),
                  _ProgressBar(progress: task.progress!, colors: colors),
                ],

                // Error message
                if (task.status == DownloadTaskStatus.error &&
                    task.errorMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    task.errorMessage!,
                    style: TextStyle(
                      color: colors.error,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder({required this.colors, required this.width, required this.height});
  final ColorScheme colors;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.play_circle_outline_rounded,
        size: 24,
        color: colors.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Status icon
// ──────────────────────────────────────────────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status, required this.colors});
  final DownloadTaskStatus status;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case DownloadTaskStatus.queued:
        icon = Icons.hourglass_empty_rounded;
        color = colors.onSurfaceVariant;
      case DownloadTaskStatus.downloading:
        icon = Icons.downloading_rounded;
        color = colors.primary;
      case DownloadTaskStatus.paused:
        icon = Icons.pause_circle_outline_rounded;
        color = colors.tertiary;
      case DownloadTaskStatus.done:
        icon = Icons.check_circle_rounded;
        color = colors.primary;
      case DownloadTaskStatus.error:
        icon = Icons.error_outline_rounded;
        color = colors.error;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Progress bar
// ──────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress, required this.colors});
  final DownloadProgress progress;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final pct = progress.percent.clamp(0.0, 100.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${pct.toStringAsFixed(1)}%',
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Row(
              children: [
                if (progress.speedLabel != null) ...[
                  Icon(Icons.speed_rounded,
                      size: 12, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    progress.speedLabel!,
                    style: TextStyle(
                        color: colors.onSurfaceVariant, fontSize: 11),
                  ),
                ],
                if (progress.etaLabel != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.timer_outlined,
                      size: 12, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'ETA ${progress.etaLabel!}',
                    style: TextStyle(
                        color: colors.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 6,
            backgroundColor: colors.surfaceContainerHighest,
          ),
        ),
        if (progress.sizeLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            progress.currentSizeLabel != null
                ? '${progress.currentSizeLabel} / ${progress.sizeLabel}'
                : progress.sizeLabel!,
            style: TextStyle(
                color: colors.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ],
    );
  }
}
