import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';

import '../../models/download_task.dart';
import '../../widgets/app_sidebar.dart';
import '../downloads/download_queue_provider.dart';
import 'settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
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
                _TopBar(colors: colors),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Settings',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: colors.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Configure default download behavior.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                              ),
                              const SizedBox(height: 28),

                              // ── Output Directory ────────────────────────
                              _SectionCard(
                                colors: colors,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Default Download Directory',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: colors.onSurface),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Where downloaded files are saved by default.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 10),
                                            decoration: BoxDecoration(
                                              color: colors
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: colors.outlineVariant),
                                            ),
                                            child: Text(
                                              state.outputDirectory ??
                                                  'Downloads (system default)',
                                              style: TextStyle(
                                                color: colors.onSurface,
                                                fontSize: 13,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _ActionButton(
                                          icon: Icons.folder_open_rounded,
                                          label: 'Browse',
                                          onPressed: () async {
                                            final result = await FilePicker
                                                .platform
                                                .getDirectoryPath();
                                            if (result != null) {
                                              await notifier
                                                  .setOutputDirectory(result);
                                            }
                                          },
                                        ),
                                        if (state.outputDirectory != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(left: 4),
                                            child: _ActionButton(
                                              icon: Icons.close_rounded,
                                              label: 'Reset',
                                              onPressed: () => notifier
                                                  .setOutputDirectory(null),
                                              isSecondary: true,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (state.isSaving)
                                const Padding(
                                  padding: EdgeInsets.only(top: 16),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                      SizedBox(width: 8),
                                      Text('Saving...'),
                                    ],
                                  ),
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
// Reusable widgets
// ──────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.colors, required this.child});
  final ColorScheme colors;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon,
          size: 16,
          color: isSecondary ? colors.onSurfaceVariant : colors.primary),
      label: Text(label,
          style: TextStyle(
              fontSize: 12,
              color: isSecondary ? colors.onSurfaceVariant : colors.primary)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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
            'Settings',
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
