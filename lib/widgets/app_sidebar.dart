import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.colors,
    this.queuedCount = 0,
  });

  final ColorScheme colors;
  final int queuedCount;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 72,
      color: colors.surfaceContainerHighest,
      child: Column(
        children: [
          const SizedBox(height: 20),
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
          _AppSidebarIcon(
            icon: Icons.home_rounded,
            active: location == '/',
            colors: colors,
            onTap: () => context.go('/'),
          ),
          _AppSidebarIcon(
            icon: Icons.queue_play_next_rounded,
            active: location == '/downloads',
            colors: colors,
            badgeCount: queuedCount,
            onTap: location == '/downloads' ? null : () => context.go('/downloads'),
          ),
          _AppSidebarIcon(
            icon: Icons.history_rounded,
            active: location == '/history',
            colors: colors,
            onTap: location == '/history' ? null : () => context.go('/history'),
          ),
          const Spacer(),
          _AppSidebarIcon(
            icon: Icons.settings_rounded,
            active: location == '/settings',
            colors: colors,
            onTap: location == '/settings' ? null : () => context.go('/settings'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _AppSidebarIcon extends StatelessWidget {
  const _AppSidebarIcon({
    required this.icon,
    this.active = false,
    required this.colors,
    this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final bool active;
  final ColorScheme colors;
  final VoidCallback? onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: active
            ? colors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: active ? colors.primary : colors.onSurfaceVariant,
        size: 22,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: badgeCount != null && badgeCount! > 0
            ? Badge(
                label: Text(
                  badgeCount! > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w700),
                ),
                smallSize: 18,
                textStyle: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w700),
                child: iconWidget,
              )
            : iconWidget,
      ),
    );
  }
}
