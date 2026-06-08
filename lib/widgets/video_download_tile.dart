import 'package:flutter/material.dart';

import '../models/video_info.dart';
import '../models/video_format.dart';

/// Callback fired when the user taps the download button inside a tile.
typedef VideoDownloadCallback = void Function(
  VideoInfo video,
  VideoFormat format,
  String? subtitleLang,
);

/// A compact horizontal tile that combines video info display and download
/// controls (format selector, subtitle dropdown, download button) into a single row.
class VideoDownloadTile extends StatefulWidget {
  final VideoInfo video;
  final VideoFormat? initialFormat;
  final String? initialSubtitleLang;
  final VideoDownloadCallback onDownload;

  const VideoDownloadTile({
    super.key,
    required this.video,
    this.initialFormat,
    this.initialSubtitleLang,
    required this.onDownload,
  });

  @override
  State<VideoDownloadTile> createState() => _VideoDownloadTileState();
}

class _VideoDownloadTileState extends State<VideoDownloadTile> {
  VideoFormat? _selectedFormat;
  String _subtitleLang = '';

  @override
  void initState() {
    super.initState();
    final formats = widget.video.formats;
    _selectedFormat = widget.initialFormat ??
        (formats.isNotEmpty ? formats.first : null);
    final initLang = widget.initialSubtitleLang ?? '';
    _subtitleLang = initLang.isNotEmpty &&
            widget.video.manualSubtitleLangs.contains(initLang)
        ? initLang
        : '';
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

  String _formatViewCount(int? count) {
    if (count == null) return '';
    if (count >= 1000000) return ' • ${(count / 1000000).toStringAsFixed(1)}M views';
    if (count >= 1000) return ' • ${(count / 1000).toStringAsFixed(1)}K views';
    return ' • $count views';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final video = widget.video;

    return SizedBox(
      height: 100,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.outlineVariant),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // ── Thumbnail ──────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 140,
                height: 78,
                child: Stack(
                  children: [
                    if (video.thumbnailUrl.isNotEmpty)
                      Image.network(
                        video.thumbnailUrl,
                        width: 140,
                        height: 78,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) =>
                            progress == null ? child : _ThumbPlaceholder(colors: colors),
                        errorBuilder: (_, _, _) =>
                            _ThumbPlaceholder(colors: colors),
                      )
                    else
                      _ThumbPlaceholder(colors: colors),
                    if (video.duration > 0)
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatDuration(video.duration),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 16),

            // ── Title + Meta ───────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: colors.onSurface,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${video.uploader}${_formatViewCount(video.viewCount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // ── Format Dropdown ────────────────────────────────────────
            DropdownButton<VideoFormat>(
              value: _selectedFormat,
              isDense: true,
              underline: const SizedBox(),
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurface,
              ),
              items: video.formats.map((f) {
                return DropdownMenuItem<VideoFormat>(
                  value: f,
                  child: Text(
                    f.label,
                    style: const TextStyle(fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedFormat = v);
              },
            ),

            const SizedBox(width: 12),

            // ── Subtitle Dropdown (manual subtitles only) ────────────
            if (video.manualSubtitleLangs.isNotEmpty) ...[
              DropdownButton<String>(
                value: _subtitleLang.isNotEmpty &&
                        video.manualSubtitleLangs.contains(_subtitleLang)
                    ? _subtitleLang
                    : '',
                isDense: true,
                underline: const SizedBox(),
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurface,
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('None',
                        style: TextStyle(fontSize: 11)),
                  ),
                  ...video.manualSubtitleLangs.map((code) {
                    final name = languageDisplayName(code);
                    return DropdownMenuItem(
                      value: code,
                      child: Text(name,
                          style: const TextStyle(fontSize: 11)),
                    );
                  }),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _subtitleLang = v);
                },
              ),
            ],

            const SizedBox(width: 8),

            // ── Download Button ────────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _selectedFormat == null
                  ? null
                  : () => widget.onDownload(
                        widget.video,
                        _selectedFormat!,
                        _subtitleLang.isEmpty ? null : _subtitleLang,
                      ),
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Download'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder({required this.colors});
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 78,
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.play_circle_outline_rounded,
        size: 32,
        color: colors.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }
}
