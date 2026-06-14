import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/platform_utils.dart';
import '../../models/download_task.dart';
import '../../widgets/app_sidebar.dart';
import '../downloads/download_queue_provider.dart';
import 'history_provider.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);
    final colors = Theme.of(context).colorScheme;
    final queueState = ref.watch(downloadQueueProvider);
    final activeCount =
        queueState.tasks.where((t) => t.status != DownloadTaskStatus.done).length;

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
                  hasHistory: state.entries.isNotEmpty,
                  onClear: state.entries.isNotEmpty
                      ? () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Clear History'),
                              content: const Text(
                                'Are you sure you want to clear all download history?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    notifier.clearHistory();
                                    Navigator.of(ctx).pop();
                                  },
                                  child: const Text('Clear'),
                                ),
                              ],
                            ),
                          );
                        }
                      : null,
                ),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : state.entries.isEmpty
                          ? _EmptyState(colors: colors)
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(32, 20, 32, 32),
                              itemCount: state.entries.length,
                              itemBuilder: (context, index) {
                                final entry = state.entries[index];
                                return _HistoryTile(
                                  entry: entry,
                                  colors: colors,
                                  onRemove: () =>
                                      notifier.removeEntry(entry.id),
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
// History Tile
// ──────────────────────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.entry,
    required this.colors,
    required this.onRemove,
  });
  final DownloadTask entry;
  final ColorScheme colors;
  final VoidCallback onRemove;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }

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
            if (entry.thumbnailUrl != null && entry.thumbnailUrl!.isNotEmpty)
              Image.network(
                entry.thumbnailUrl!,
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
            if (entry.duration > 0)
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
                    _formatDuration(entry.duration),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          _buildThumbnail(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.format.label} • ${entry.completedAt != null ? _formatDate(entry.completedAt!) : ''}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (entry.status == DownloadTaskStatus.done &&
              entry.outputPath != null)
            SizedBox(
              height: 32,
              child: IconButton(
                tooltip: 'Open folder',
                onPressed: () =>
                    PlatformUtils.openContainingFolder(entry.outputPath!),
                icon: Icon(Icons.folder_open_rounded,
                    size: 16, color: colors.primary),
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          SizedBox(
            height: 32,
            child: IconButton(
              onPressed: onRemove,
              icon: Icon(Icons.close_rounded,
                  size: 16, color: colors.onSurfaceVariant),
              style: IconButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
// Empty State
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
          Icon(Icons.history_rounded,
              size: 64,
              color: colors.onSurfaceVariant.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No download history',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completed downloads will appear here.',
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
// Top bar
// ──────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.colors,
    required this.hasHistory,
    this.onClear,
  });
  final ColorScheme colors;
  final bool hasHistory;
  final VoidCallback? onClear;

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
            'History',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          if (hasHistory && onClear != null)
            TextButton.icon(
              onPressed: onClear,
              icon: Icon(Icons.delete_outline_rounded,
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
          const SizedBox(width: 8),
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
