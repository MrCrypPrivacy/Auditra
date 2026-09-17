import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/theme/typography.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const PrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.accent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label, style: AppTypography.body.copyWith(color: theme.onAccent)),
      ),
    );
  }
}
