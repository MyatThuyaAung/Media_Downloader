import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/download_task.dart';
import '../../models/download_progress.dart';
import '../../widgets/app_sidebar.dart';
import 'download_queue_provider.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                ),
                Expanded(
                  child: state.tasks.isEmpty
                      ? _EmptyState(colors: colors)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                          itemCount: state.tasks.length,
                          itemBuilder: (context, index) {
                            final task = state.tasks[index];
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



// ──────────────────────────────────────────────────────────────────────────────
// Top bar with global controls
// ──────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.colors,
    required this.hasActive,
    required this.hasPaused,
    required this.onPauseAll,
    required this.onResumeAll,
  });
  final ColorScheme colors;
  final bool hasActive;
  final bool hasPaused;
  final VoidCallback? onPauseAll;
  final VoidCallback? onResumeAll;

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
  });

  final DownloadTask task;
  final ColorScheme colors;
  final ThemeData theme;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _StatusIcon(status: task.status, colors: colors),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (task.uploader != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          task.uploader!,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // Pause button (downloading)
              if (onPause != null)
                SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause_rounded, size: 14),
                    label: const Text('Pause', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

              // Resume button (paused)
              if (onResume != null)
                SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow_rounded, size: 14),
                    label: const Text('Resume', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

              // Cancel button (queued)
              if (onCancel != null)
                SizedBox(
                  height: 32,
                  child: OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.stop_rounded, size: 14),
                    label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

              // Dismiss button (done / error)
              if (onRemove != null)
                SizedBox(
                  height: 32,
                  child: TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Phase / status label (e.g. "Merging Audio & Video...", "Resuming...")
          if (task.status == DownloadTaskStatus.downloading &&
              task.progress != null &&
              task.progress!.phase != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.progress!.phase!,
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Numeric progress bar (when we have real percent data)
          if (task.status == DownloadTaskStatus.downloading &&
              task.progress != null &&
              task.progress!.percent > 0) ...[
            const SizedBox(height: 12),
            _ProgressBar(progress: task.progress!, colors: colors),
          ],

          // Error message
          if (task.status == DownloadTaskStatus.error &&
              task.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              task.errorMessage!,
              style: TextStyle(
                color: colors.error,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
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
