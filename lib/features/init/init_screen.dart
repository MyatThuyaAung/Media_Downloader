import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'init_provider.dart';

class InitScreen extends ConsumerStatefulWidget {
  const InitScreen({super.key});

  @override
  ConsumerState<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends ConsumerState<InitScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(initProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(initProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Center(
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.download_for_offline_rounded,
                  size: 64,
                  color: colors.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Media Downloader',
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Preparing components…',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 40),
                if (state.status == InitStatus.error) ...[
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: colors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.error ?? 'Unknown error',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.error,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(initProvider.notifier).initialize();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ] else ...[
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(strokeWidth: 4),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: const LinearProgressIndicator(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.step,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
