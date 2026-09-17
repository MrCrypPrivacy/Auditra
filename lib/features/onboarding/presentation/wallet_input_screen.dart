import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/network/hyperliquid_client.dart';
import '../../../core/storage/fills_local_store.dart';
import '../../../core/storage/wallet_local_store.dart';
import '../../../core/storage/wallet_profile.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/language_switcher.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

class WalletInputScreen extends StatefulWidget {
  const WalletInputScreen({super.key});

  @override
  State<WalletInputScreen> createState() => _WalletInputScreenState();
}

class _WalletInputScreenState extends State<WalletInputScreen> {
  final _nameController = TextEditingController(text: 'Arbiter');
  final _addressController = TextEditingController();
  final _client = HyperliquidClient();
  final _walletStore = WalletLocalStore();
  bool _loading = false;
  String? _error;

  Future<void> _connect() async {
    final address = _addressController.text.trim();
    final name = _nameController.text.trim();
    if (address.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final fills = await _client.fetchUserFills(address);
      final store = FillsLocalStore(address);
      await store.mergeAndSave(fills);
      await _walletStore.addWallet(
        WalletProfile(name: name.isEmpty ? address : name, address: address),
      );
      final allFills = await store.loadAll();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DashboardScreen(
            wallet: WalletProfile(name: name.isEmpty ? address : name, address: address),
            fills: allFills,
          ),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.background,
      body: Stack(
        children: [
          Positioned(top: 16, right: 16, child: const LanguageSwitcher()),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(
                      'assets/logo.svg',
                      height: 40,
                      colorFilter: ColorFilter.mode(theme.accent, BlendMode.srcIn),
                    ),
                    const SizedBox(height: 24),
                    Text(l10n.connectWalletTitle, style: AppTypography.display.copyWith(color: theme.textPrimary)),
                    const SizedBox(height: 8),
                    Text(l10n.connectWalletBody, style: AppTypography.body.copyWith(color: theme.textPrimary)),
                    const SizedBox(height: 24),
                    Text(l10n.walletNameLabel, style: AppTypography.caption.copyWith(color: theme.textSecondary)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _nameController,
                      style: AppTypography.body.copyWith(color: theme.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n.walletNameHint,
                        filled: true,
                        fillColor: theme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      style: AppTypography.body.copyWith(color: theme.textPrimary),
                      decoration: InputDecoration(
                        hintText: '0x...',
                        filled: true,
                        fillColor: theme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: theme.border),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: theme.negative)),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _loading ? l10n.connectingButton : l10n.connectButton,
                      onPressed: _loading ? null : _connect,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
