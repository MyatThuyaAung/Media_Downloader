import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/download_task.dart';
import '../../models/playlist_info.dart';
import '../../models/video_format.dart';
import '../../widgets/app_sidebar.dart';

import '../../widgets/video_download_tile.dart';
import '../downloads/download_queue_provider.dart';
import '../settings/settings_provider.dart';
import 'home_provider.dart';

const _formatPresets = [
  VideoFormat(
    formatId: 'bestvideo[height<=?1080]+bestaudio/best',
    ext: 'mkv',
    height: 1080,
    label: '1080p',
  ),
  VideoFormat(
    formatId: 'bestvideo[height<=?720]+bestaudio/best',
    ext: 'mkv',
    height: 720,
    label: '720p',
  ),
  VideoFormat(
    formatId: 'bestvideo[height<=?480]+bestaudio/best',
    ext: 'mkv',
    height: 480,
    label: '480p',
  ),
  VideoFormat(
    formatId: 'bestvideo[height<=?360]+bestaudio/best',
    ext: 'mkv',
    height: 360,
    label: '360p',
  ),
  VideoFormat(
    formatId: 'bestaudio/best',
    ext: 'm4a',
    label: 'Audio only',
  ),
];

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final queueState = ref.watch(downloadQueueProvider);
    final settings = ref.watch(settingsProvider);
    final outputDir = settings.isLoading ? null : settings.outputDirectory;
    final notifier = ref.read(homeProvider.notifier);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final activeCount =
        queueState.tasks.where((t) => t.status != DownloadTaskStatus.done).length;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Row(
        children: [
          // ── Left sidebar ────────────────────────────────────────────────
          AppSidebar(colors: colors, queuedCount: activeCount),

          // ── Main content ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top bar
                _TopBar(colors: colors),

                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section title
                        Text(
                          'Download Media',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Paste any video URL to fetch info and download.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── URL Input Card ──────────────────────────────
                        _UrlInputCard(
                          colors: colors,
                          theme: theme,
                          isLoading: state.isLoading,
                          cookiesBrowser: state.cookiesBrowser,
                          onChanged: notifier.updateUrl,
                          onFetch: state.isLoading
                              ? null
                              : notifier.fetchVideoInfo,
                          onCookiesBrowserChanged:
                              notifier.updateCookiesBrowser,
                        ),

                        const SizedBox(height: 24),

                        // ── Error banner ────────────────────────────────
                        if (state.error != null)
                          _ErrorBanner(
                            message: state.error!,
                            colors: colors,
                          ),

                        // ── Loading indicator ───────────────────────────
                        if (state.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: _FetchingIndicator(),
                            ),
                          ),

                        // ── Playlist entries inline ─────────────────────────
                        if (state.playlistInfo != null && !state.isLoading)
                          _InlinePlaylistView(
                            playlistInfo: state.playlistInfo!,
                            outputDirectory: outputDir,
                          ),

                        // ── Video tile with integrated download controls ──
                        if (state.videoInfo != null && !state.isLoading)
                          VideoDownloadTile(
                            video: state.videoInfo!,
                            initialFormat: state.videoInfo!.formats.isNotEmpty
                                ? state.videoInfo!.formats.first
                                : null,
                            initialSubtitleLang: state.subtitleLang,
                            onDownload: (video, format, subtitleLang) {
                              notifier.startDownload(
                                video: video,
                                format: format,
                                subtitleLang: subtitleLang,
                                outputDirectory: outputDir,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Added to download queue!'),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
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
// Top bar
// ──────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.colors});
  final ColorScheme colors;

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
            'Media Downloader',
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const Spacer(),
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
// URL input card
// ──────────────────────────────────────────────────────────────────────────────

class _UrlInputCard extends StatefulWidget {
  const _UrlInputCard({
    required this.colors,
    required this.theme,
    required this.isLoading,
    required this.cookiesBrowser,
    required this.onChanged,
    required this.onFetch,
    required this.onCookiesBrowserChanged,
  });

  final ColorScheme colors;
  final ThemeData theme;
  final bool isLoading;
  final String? cookiesBrowser;
  final ValueChanged<String> onChanged;
  final VoidCallback? onFetch;
  final ValueChanged<String?> onCookiesBrowserChanged;

  @override
  State<_UrlInputCard> createState() => _UrlInputCardState();
}

class _UrlInputCardState extends State<_UrlInputCard> {
  bool _isExpanded = false;
  final _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _onUrlChanged(String value) {
    widget.onChanged(value);
    setState(() {});
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.trim().isNotEmpty) {
      final url = data.text!.trim();
      _urlController.text = url;
      widget.onChanged(url);
    }
  }

  void _onFetchPressed() {
    if (_urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please paste or type a video URL first.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    widget.onFetch?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final theme = widget.theme;

    final browsers = [
      'None',
      'Chrome',
      'Firefox',
      'Edge',
      'Brave',
      'Opera',
      'Vivaldi',
      'Safari',
    ];

    final selectedBrowser = browsers.firstWhere(
      (b) => b.toLowerCase() == (widget.cookiesBrowser ?? 'none').toLowerCase(),
      orElse: () => 'None',
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video URL',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  onChanged: _onUrlChanged,
                  onSubmitted: (_) => _onFetchPressed(),
                  style: TextStyle(color: colors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'https://youtube.com/watch?v=...',
                    hintStyle:
                        TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.link_rounded,
                        color: colors.primary, size: 20),
                    suffixIcon: _urlController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _urlController.clear();
                              _onUrlChanged('');
                            },
                            icon: Icon(Icons.close_rounded,
                                size: 18, color: colors.onSurfaceVariant),
                          )
                        : null,
                    filled: true,
                    fillColor: colors.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: colors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 44,
                child: IconButton.filled(
                  tooltip: 'Paste from clipboard',
                  onPressed: _pasteFromClipboard,
                  icon: Icon(Icons.content_paste_rounded,
                      size: 18, color: colors.primary),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _FetchButton(
                isLoading: widget.isLoading,
                onPressed: _onFetchPressed,
                colors: colors,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Expandable settings header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Advanced Options',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: colors.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cookies Source',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select a browser to read active session cookies from. This allows downloading restricted, private, or age-gated videos and helps bypass bot detection.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey(selectedBrowser),
                            initialValue: selectedBrowser,
                            items: browsers
                                .map(
                                  (b) => DropdownMenuItem<String>(
                                    value: b,
                                    child: Row(
                                      children: [
                                        Icon(
                                          b == 'None'
                                              ? Icons.public_off_rounded
                                              : Icons.cookie_rounded,
                                          size: 16,
                                          color: b == 'None'
                                              ? colors.onSurfaceVariant
                                              : colors.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          b,
                                          style: TextStyle(
                                            color: colors.onSurface,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: widget.isLoading
                                ? null
                                : (String? val) {
                                    if (val != null) {
                                      widget.onCookiesBrowserChanged(
                                        val == 'None' ? null : val,
                                      );
                                    }
                                  },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: colors.surfaceContainer,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            dropdownColor: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _FetchButton extends StatelessWidget {
  const _FetchButton({
    required this.isLoading,
    required this.onPressed,
    required this.colors,
  });

  final bool isLoading;
  final VoidCallback? onPressed;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onPrimary,
                ),
              )
            : const Icon(Icons.search_rounded, size: 18),
        label: Text(isLoading ? 'Fetching...' : 'Fetch Info'),
        style: FilledButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Fetching indicator
// ──────────────────────────────────────────────────────────────────────────────

class _FetchingIndicator extends StatelessWidget {
  const _FetchingIndicator();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: colors.primary),
        const SizedBox(height: 16),
        Text(
          'Fetching video information...',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Error banner
// ──────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.colors});
  final String message;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              color: colors.onErrorContainer, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              message,
              style: TextStyle(
                  color: colors.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Inline playlist view — entries with per-entry format/CC selection
// ──────────────────────────────────────────────────────────────────────────────

const _subtitleOptions = [
  '',
  'en', 'es', 'ja', 'fr', 'de', 'ko', 'zh', 'pt', 'ru',
  'it', 'ar', 'hi', 'id', 'th', 'vi', 'nl', 'pl', 'tr',
];

String _subtitleLabel(String code) {
  if (code.isEmpty) return 'No CC';
  const names = <String, String>{
    'en': 'English', 'es': 'Spanish', 'ja': 'Japanese',
    'fr': 'French', 'de': 'German', 'ko': 'Korean',
    'zh': 'Chinese', 'pt': 'Portuguese', 'ru': 'Russian',
    'it': 'Italian', 'ar': 'Arabic', 'hi': 'Hindi',
    'id': 'Indonesian', 'th': 'Thai', 'vi': 'Vietnamese',
    'nl': 'Dutch', 'pl': 'Polish', 'tr': 'Turkish',
  };
  return names[code] ?? code.toUpperCase();
}

class _InlinePlaylistView extends StatefulWidget {
  final PlaylistInfo playlistInfo;
  final String? outputDirectory;

  const _InlinePlaylistView({
    required this.playlistInfo,
    this.outputDirectory,
  });

  @override
  State<_InlinePlaylistView> createState() => _InlinePlaylistViewState();
}

class _InlinePlaylistViewState extends State<_InlinePlaylistView> {
  final Set<String> _selectedIds = {};
  final Map<String, VideoFormat> _entryFormats = {};
  final Map<String, String> _entrySubtitleLangs = {};

  @override
  void initState() {
    super.initState();
    for (final entry in widget.playlistInfo.entries) {
      _selectedIds.add(entry.id);
      _entryFormats[entry.id] = _formatPresets.first;
      _entrySubtitleLangs[entry.id] = '';
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds.addAll(widget.playlistInfo.entries.map((e) => e.id));
    });
  }

  void _unselectAll() {
    setState(() {
      _selectedIds.clear();
    });
  }

  void _downloadSelected(BuildContext context, WidgetRef ref) {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one video to proceed.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final notifier = ref.read(downloadQueueProvider.notifier);

    for (final entry in widget.playlistInfo.entries) {
      if (!_selectedIds.contains(entry.id)) continue;

      final format = _entryFormats[entry.id] ?? _formatPresets.first;
      final subtitleLang = _entrySubtitleLangs[entry.id] ?? '';

      notifier.addTask(
        url: entry.url,
        title: entry.title,
        thumbnailUrl: entry.thumbnailUrl,
        uploader: entry.uploader ?? widget.playlistInfo.uploader,
        format: format,
        subtitleLang: subtitleLang.isEmpty ? null : subtitleLang,
        outputDirectory: widget.outputDirectory,
        duration: entry.duration,
        viewCount: entry.viewCount,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_selectedIds.length} video(s) to download queue!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final entries = widget.playlistInfo.entries;
    final selectedCount = _selectedIds.length;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.queue_play_next_rounded,
                      color: colors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.playlistInfo.title,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.playlistInfo.uploader != null)
                        Text(
                          widget.playlistInfo.uploader!,
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${entries.length} video${entries.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: colors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Selection bar ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                Text(
                  selectedCount == entries.length
                      ? 'All selected'
                      : '$selectedCount of ${entries.length} selected',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                _SelectionChip(
                  label: 'Select All',
                  icon: Icons.select_all_rounded,
                  onTap: _selectAll,
                  colors: colors,
                ),
                const SizedBox(width: 4),
                _SelectionChip(
                  label: 'Unselect All',
                  icon: Icons.deselect_rounded,
                  onTap: _unselectAll,
                  colors: colors,
                ),
              ],
            ),
          ),

          // ── Entries list ──────────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 400,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isSelected = _selectedIds.contains(entry.id);
                return _PlaylistEntryTile(
                  entry: entry,
                  isSelected: isSelected,
                  selectedFormat: _entryFormats[entry.id] ?? _formatPresets.first,
                  selectedSubtitleLang: _entrySubtitleLangs[entry.id] ?? '',
                  colors: colors,
                  formatDuration: _formatDuration,
                  onToggle: () => _toggleSelection(entry.id),
                  onFormatChanged: (f) {
                    setState(() => _entryFormats[entry.id] = f);
                  },
                  onSubtitleChanged: (v) {
                    setState(() => _entrySubtitleLangs[entry.id] = v ?? '');
                  },
                );
              },
            ),
          ),

          // ── Download button ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              child: Consumer(
                builder: (context, ref, _) {
                  return FilledButton.icon(
                    onPressed: selectedCount > 0
                        ? () => _downloadSelected(context, ref)
                        : null,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text(
                      selectedCount > 0
                          ? 'Download Selected ($selectedCount)'
                          : 'Select videos to download',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaylistEntryTile extends StatelessWidget {
  final PlaylistEntry entry;
  final bool isSelected;
  final VideoFormat selectedFormat;
  final String selectedSubtitleLang;
  final ColorScheme colors;
  final String Function(int) formatDuration;
  final VoidCallback onToggle;
  final ValueChanged<VideoFormat> onFormatChanged;
  final ValueChanged<String?> onSubtitleChanged;

  const _PlaylistEntryTile({
    required this.entry,
    required this.isSelected,
    required this.selectedFormat,
    required this.selectedSubtitleLang,
    required this.colors,
    required this.formatDuration,
    required this.onToggle,
    required this.onFormatChanged,
    required this.onSubtitleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.25)
                  : colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 6),
              // ── Thumbnail ──────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 72,
                  height: 40,
                  child: Stack(
                    children: [
                      if (entry.thumbnailUrl != null &&
                          entry.thumbnailUrl!.isNotEmpty)
                        Image.network(
                          entry.thumbnailUrl!,
                          width: 72,
                          height: 40,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : _EntryThumbPlaceholder(colors: colors),
                          errorBuilder: (_, _, _) =>
                              _EntryThumbPlaceholder(colors: colors),
                        )
                      else
                        _EntryThumbPlaceholder(colors: colors),
                      if (entry.duration > 0)
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 3, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              formatDuration(entry.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ── Title + uploader ────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (entry.uploader != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        entry.uploader!,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // ── Format dropdown ─────────────────────────────────────
              SizedBox(
                height: 28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<VideoFormat>(
                        value: selectedFormat,
                        isDense: true,
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.onSurface,
                        ),
                        items: _formatPresets.map((f) {
                          return DropdownMenuItem<VideoFormat>(
                            value: f,
                            child: Text(f.label,
                                style: const TextStyle(fontSize: 10)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) onFormatChanged(v);
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // ── Subtitle dropdown ──────────────────────────────────
              SizedBox(
                height: 28,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSubtitleLang,
                        isDense: true,
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.onSurface,
                        ),
                        items: _subtitleOptions.map((code) {
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text(
                              _subtitleLabel(code),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => onSubtitleChanged(v),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryThumbPlaceholder extends StatelessWidget {
  const _EntryThumbPlaceholder({required this.colors});
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 40,
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.play_circle_outline_rounded,
        size: 16,
        color: colors.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }
}

class _SelectionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final ColorScheme colors;

  const _SelectionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 12, color: colors.primary),
      label: Text(label,
          style: TextStyle(fontSize: 10, color: colors.primary)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

