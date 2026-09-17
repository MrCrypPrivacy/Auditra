import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/theme_controller.dart';
import '../../core/theme/typography.dart';
import '../../l10n/generated/app_localizations.dart';

class AppSidebar extends StatelessWidget {
  final String walletName;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onSettingsTap;

  const AppSidebar({
    super.key,
    required this.walletName,
    required this.selectedIndex,
    required this.onSelect,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: 220,
      color: theme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/logo.svg',
                height: 24,
                colorFilter: ColorFilter.mode(theme.accent, BlendMode.srcIn),
              ),
              const SizedBox(width: 10),
              Text('Auditra', style: AppTypography.title.copyWith(color: theme.textPrimary)),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(walletName, style: AppTypography.caption.copyWith(color: theme.textSecondary)),
          ),
          const SizedBox(height: 32),
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: l10n.sidebarOverview,
            active: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          _SidebarItem(
            icon: Icons.receipt_long_outlined,
            label: l10n.sidebarTrades,
            active: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
          _SidebarItem(
            icon: Icons.psychology_outlined,
            label: l10n.sidebarBehavior,
            active: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),
          _SidebarItem(
            icon: Icons.rule_outlined,
            label: l10n.sidebarRules,
            active: selectedIndex == 3,
            onTap: () => onSelect(3),
          ),
          _SidebarItem(
            icon: Icons.settings_outlined,
            label: l10n.sidebarSettings,
            active: false,
            onTap: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? theme.background : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: active ? theme.accent : theme.textSecondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: AppTypography.body.copyWith(
                color: active ? theme.textPrimary : theme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
