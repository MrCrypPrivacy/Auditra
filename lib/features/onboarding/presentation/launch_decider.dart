import 'package:flutter/material.dart';

import '../../../core/storage/fills_local_store.dart';
import '../../../core/storage/wallet_local_store.dart';
import '../../../core/theme/theme_controller.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import 'wallet_input_screen.dart';

class LaunchDecider extends StatefulWidget {
  const LaunchDecider({super.key});

  @override
  State<LaunchDecider> createState() => _LaunchDeciderState();
}

class _LaunchDeciderState extends State<LaunchDecider> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  Future<void> _decide() async {
    final walletStore = WalletLocalStore();
    final address = await walletStore.loadActiveAddress();

    if (address == null) {
      _replaceWith(const WalletInputScreen());
      return;
    }

    final wallets = await walletStore.loadWallets();
    final wallet = wallets.firstWhere(
      (w) => w.address.toLowerCase() == address.toLowerCase(),
      orElse: () => wallets.first,
    );

    final fills = await FillsLocalStore(address).loadAll();
    _replaceWith(DashboardScreen(wallet: wallet, fills: fills));
  }

  void _replaceWith(Widget screen) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);

    return Scaffold(
      backgroundColor: theme.background,
      body: Center(
        child: CircularProgressIndicator(color: theme.accent),
      ),
    );
  }
}
