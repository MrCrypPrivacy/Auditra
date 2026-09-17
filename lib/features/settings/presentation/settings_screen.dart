import 'package:flutter/material.dart';

import '../../../core/l10n/locale_controller.dart';
import '../../../core/network/export_import_service.dart';
import '../../../core/network/hyperliquid_client.dart';
import '../../../core/storage/fills_local_store.dart';
import '../../../core/storage/reset_service.dart';
import '../../../core/storage/wallet_local_store.dart';
import '../../../core/storage/wallet_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../onboarding/presentation/launch_decider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _walletStore = WalletLocalStore();
  List<WalletProfile> _wallets = [];
  String? _activeAddress;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final wallets = await _walletStore.loadWallets();
    final active = await _walletStore.loadActiveAddress();
    if (mounted) setState(() {
      _wallets = wallets;
      _activeAddress = active;
    });
  }

  void _goToLaunchDecider() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LaunchDecider()),
      (route) => false,
    );
  }

  Future<void> _switchWallet(String address) async {
    await _walletStore.setActive(address);
    _goToLaunchDecider();
  }

  Future<void> _removeWallet(String address) async {
    await _walletStore.removeWallet(address);
    await _load();
    if (_activeAddress?.toLowerCase() == address.toLowerCase()) {
      _goToLaunchDecider();
    }
  }

  Future<void> _addWallet(BuildContext context) async {
    final theme = AppThemeScope.themeOf(context);
    final nameController = TextEditingController(text: 'Hyperliquid');
    final addressController = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.surface,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: theme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Wallet name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    style: TextStyle(color: theme.textPrimary),
                    decoration: const InputDecoration(labelText: '0x...'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: TextStyle(color: theme.negative, fontSize: 12)),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final address = addressController.text.trim();
                    if (address.isEmpty) return;
                    setDialogState(() => error = null);
                    try {
                      final fills = await HyperliquidClient().fetchUserFills(address);
                      await FillsLocalStore(address).mergeAndSave(fills);
                      await _walletStore.addWallet(WalletProfile(
                        name: nameController.text.trim().isEmpty
                            ? address
                            : nameController.text.trim(),
                        address: address,
                      ));
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      _goToLaunchDecider();
                    } catch (e) {
                      setDialogState(() => error = e.toString());
                    }
                  },
                  child: Text('Add', style: TextStyle(color: theme.accent)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _resetAllData(BuildContext context) async {
    final theme = AppThemeScope.themeOf(context);
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.surface,
          title: Text(l10n.resetConfirmTitle, style: TextStyle(color: theme.textPrimary)),
          content: Text(l10n.resetConfirmBody, style: TextStyle(color: theme.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancelButton, style: TextStyle(color: theme.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.confirmButton, style: TextStyle(color: theme.negative)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await ResetService().wipeAllData();
    if (!context.mounted) return;
    _goToLaunchDecider();
  }

  Future<void> _export(BuildContext context) async {
    if (_activeAddress == null) return;
    setState(() => _busy = true);
    try {
      final fills = await FillsLocalStore(_activeAddress!).loadAll();
      final path = await ExportImportService().exportFills(_activeAddress!, fills);
      if (context.mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv(BuildContext context) async {
    if (_activeAddress == null) return;
    setState(() => _busy = true);
    try {
      final fills = await FillsLocalStore(_activeAddress!).loadAll();
      final path = await ExportImportService().exportFillsCsv(_activeAddress!, fills);
      if (context.mounted && path != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to $path')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import(BuildContext context) async {
    if (_activeAddress == null) return;
    setState(() => _busy = true);
    try {
      final imported = await ExportImportService().importFills();
      if (imported == null) return;
      final added = await FillsLocalStore(_activeAddress!).mergeAndSave(imported);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Imported $added new trades')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final themeController = AppThemeScope.of(context);
    final localeController = AppLocaleScope.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(l10n.sidebarSettings, style: AppTypography.display.copyWith(color: theme.textPrimary)),
                ],
              ),
              const SizedBox(height: 24),

              Text(l10n.walletsTitle, style: AppTypography.title.copyWith(color: theme.textPrimary)),
              const SizedBox(height: 12),
              ..._wallets.map((wallet) {
                final isActive = wallet.address.toLowerCase() == _activeAddress?.toLowerCase();
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isActive ? theme.accent : theme.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(wallet.name, style: AppTypography.body.copyWith(color: theme.textPrimary)),
                            Text(wallet.address, style: AppTypography.caption.copyWith(color: theme.textSecondary)),
                          ],
                        ),
                      ),
                      if (!isActive)
                        TextButton(
                          onPressed: () => _switchWallet(wallet.address),
                          child: const Text('Use'),
                        ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, size: 18, color: theme.textSecondary),
                        onPressed: () => _removeWallet(wallet.address),
                      ),
                    ],
                  ),
                );
              }),
              TextButton.icon(
                onPressed: () => _addWallet(context),
                icon: Icon(Icons.add, color: theme.accent),
                label: Text(l10n.addWalletButton, style: TextStyle(color: theme.accent)),
              ),

              const SizedBox(height: 32),
              Text('Theme', style: AppTypography.title.copyWith(color: theme.textPrimary)),
              const SizedBox(height: 12),
              ValueListenableBuilder<AppTheme>(
                valueListenable: themeController,
                builder: (context, current, _) {
                  return Wrap(
                    spacing: 12,
                    children: AppTheme.all.map((option) {
                      final selected = option.name == current.name;
                      return ChoiceChip(
                        label: Text(option.name),
                        selected: selected,
                        onSelected: (_) => themeController.select(option),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 32),
              Text('Language', style: AppTypography.title.copyWith(color: theme.textPrimary)),
              const SizedBox(height: 12),
              ValueListenableBuilder<Locale>(
                valueListenable: localeController,
                builder: (context, current, _) {
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AppLocales.supported.map((locale) {
                      final selected = locale.languageCode == current.languageCode;
                      return ChoiceChip(
                        label: Text(AppLocales.nativeNames[locale.languageCode] ?? locale.languageCode),
                        selected: selected,
                        onSelected: (_) => localeController.select(locale),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 32),
              Text('Data', style: AppTypography.title.copyWith(color: theme.textPrimary)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: l10n.exportButton,
                      onPressed: _busy ? null : () => _export(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: l10n.exportCsvButton,
                      onPressed: _busy ? null : () => _exportCsv(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: l10n.importButton,
                      onPressed: _busy ? null : () => _import(context),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.negative.withOpacity(0.4)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _resetAllData(context),
                      child: Text(l10n.resetButton, style: TextStyle(color: theme.negative)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
