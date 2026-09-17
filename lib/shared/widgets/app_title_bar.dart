import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/theme/theme_controller.dart';

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: () async {
        final isMaximized = await windowManager.isMaximized();
        isMaximized ? windowManager.unmaximize() : windowManager.maximize();
      },
      child: Container(
        height: 32,
        color: theme.surface,
        child: Row(
          children: [
            const SizedBox(width: 12),
            Text(
              'AUDITRA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: theme.textSecondary,
              ),
            ),
            const Spacer(),
            _WindowButton(icon: Icons.remove, onPressed: windowManager.minimize),
            _WindowButton(
              icon: Icons.crop_square,
              onPressed: () async {
                final isMaximized = await windowManager.isMaximized();
                isMaximized ? windowManager.unmaximize() : windowManager.maximize();
              },
            ),
            _WindowButton(icon: Icons.close, onPressed: windowManager.close, isClose: true),
          ],
        ),
      ),
      ),
    );
  }
}

class _WindowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  const _WindowButton({required this.icon, required this.onPressed, this.isClose = false});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);

    return InkWell(
      onTap: onPressed,
      hoverColor: isClose ? theme.negative : theme.background,
      child: SizedBox(
        width: 40,
        height: 32,
        child: Icon(icon, size: 14, color: theme.textSecondary),
      ),
    );
  }
}
