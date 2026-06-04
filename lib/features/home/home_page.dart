import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/download_progress.dart';
import '../../models/video_format.dart';
import '../../widgets/video_info_card.dart';
import 'home_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Row(
        children: [
          // ── Left sidebar ────────────────────────────────────────────────
          _Sidebar(colors: colors),

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

                        // ── Video info card ─────────────────────────────
                        if (state.videoInfo != null && !state.isLoading) ...[
                          VideoInfoCard(videoInfo: state.videoInfo!),

                          const SizedBox(height: 20),

                          // ── Format + Download section ───────────────
                          if (state.videoInfo!.formats.isNotEmpty)
                            _FormatDownloadSection(
                              formats: state.videoInfo!.formats,
                              selectedFormat: state.selectedFormat,
                              isDownloading: state.isDownloading,
                              progress: state.downloadProgress,
                              colors: colors,
                              theme: theme,
                              onFormatChanged: notifier.selectFormat,
                              onDownload: state.isDownloading
                                  ? null
                                  : notifier.startDownload,
                              onCancel: notifier.cancelDownload,
                            ),
                        ],
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
// Sidebar
// ──────────────────────────────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.colors});
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      color: colors.surfaceContainerHighest,
      child: Column(
        children: [
          const SizedBox(height: 20),
          // App icon / logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.download_rounded,
                color: colors.onPrimary, size: 24),
          ),
          const SizedBox(height: 32),
          _SidebarIcon(icon: Icons.home_rounded, active: true, colors: colors),
          _SidebarIcon(icon: Icons.queue_play_next_rounded, colors: colors),
          _SidebarIcon(icon: Icons.history_rounded, colors: colors),
          const Spacer(),
          _SidebarIcon(icon: Icons.settings_rounded, colors: colors),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  const _SidebarIcon({
    required this.icon,
    this.active = false,
    required this.colors,
  });
  final IconData icon;
  final bool active;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Tooltip(
        message: '',
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: active
                ? colors.primary.withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: active ? colors.primary : colors.onSurfaceVariant,
            size: 22,
          ),
        ),
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
                  onChanged: widget.onChanged,
                  onSubmitted: (_) => widget.onFetch?.call(),
                  style: TextStyle(color: colors.onSurface),
                  decoration: InputDecoration(
                    hintText: 'https://youtube.com/watch?v=...',
                    hintStyle:
                        TextStyle(color: colors.onSurfaceVariant.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.link_rounded,
                        color: colors.primary, size: 20),
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
              const SizedBox(width: 12),
              _FetchButton(
                isLoading: widget.isLoading,
                onPressed: widget.onFetch,
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
                        color: colors.surfaceContainerHighest.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: colors.outlineVariant.withOpacity(0.5)),
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
                            value: selectedBrowser,
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
        border: Border.all(color: colors.error.withOpacity(0.3)),
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
// Format + Download section
// ──────────────────────────────────────────────────────────────────────────────

class _FormatDownloadSection extends StatelessWidget {
  const _FormatDownloadSection({
    required this.formats,
    required this.selectedFormat,
    required this.isDownloading,
    required this.progress,
    required this.colors,
    required this.theme,
    required this.onFormatChanged,
    required this.onDownload,
    required this.onCancel,
  });

  final List<VideoFormat> formats;
  final VideoFormat? selectedFormat;
  final bool isDownloading;
  final DownloadProgress? progress;
  final ColorScheme colors;
  final ThemeData theme;
  final ValueChanged<VideoFormat> onFormatChanged;
  final VoidCallback? onDownload;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
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
            'Download Options',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Format dropdown
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<VideoFormat>(
                  value: selectedFormat,
                  items: formats
                      .map(
                        (f) => DropdownMenuItem<VideoFormat>(
                          value: f,
                          child: Text(
                            f.toString(),
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: isDownloading
                      ? null
                      : (VideoFormat? v) {
                          if (v != null) onFormatChanged(v);
                        },
                  decoration: InputDecoration(
                    labelText: 'Format',
                    labelStyle:
                        TextStyle(color: colors.onSurfaceVariant),
                    prefixIcon: Icon(Icons.high_quality_rounded,
                        color: colors.primary, size: 20),
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
                  dropdownColor: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),

              // Download / Cancel button
              isDownloading
                  ? OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.error,
                        side: BorderSide(color: colors.error),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: onDownload,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
            ],
          ),

          // Progress section
          if (isDownloading && progress != null) ...[
            const SizedBox(height: 20),
            _DownloadProgressWidget(progress: progress!, colors: colors),
          ],

          // Done banner
          if (!isDownloading && progress == null &&
              selectedFormat != null) ...[
            // Intentionally empty — done state cleared by provider
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Download progress widget
// ──────────────────────────────────────────────────────────────────────────────

class _DownloadProgressWidget extends StatelessWidget {
  const _DownloadProgressWidget({
    required this.progress,
    required this.colors,
  });

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
                fontSize: 13,
              ),
            ),
            Row(
              children: [
                if (progress.speedLabel != null) ...[
                  Icon(Icons.speed_rounded,
                      size: 14, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    progress.speedLabel!,
                    style: TextStyle(
                        color: colors.onSurfaceVariant, fontSize: 12),
                  ),
                ],
                if (progress.etaLabel != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.timer_outlined,
                      size: 14, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    'ETA ${progress.etaLabel!}',
                    style: TextStyle(
                        color: colors.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct / 100,
            minHeight: 8,
            backgroundColor: colors.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(colors.primary),
          ),
        ),
        if (progress.sizeLabel != null) ...[
          const SizedBox(height: 6),
          Text(
            progress.sizeLabel!,
            style: TextStyle(
                color: colors.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ],
    );
  }
}