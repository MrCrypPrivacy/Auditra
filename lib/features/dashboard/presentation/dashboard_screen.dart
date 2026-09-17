import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/filters/period_filter.dart';
import '../../../core/network/hyperliquid_client.dart';
import '../../../core/network/hyperliquid_ws_client.dart';
import '../../../core/rules/trade_rule.dart';
import '../../../core/storage/fills_local_store.dart';
import '../../../core/storage/rules_local_store.dart';
import '../../../core/storage/wallet_local_store.dart';
import '../../../core/storage/wallet_profile.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_sidebar.dart';
import '../../../shared/widgets/language_switcher.dart';
import '../../../shared/widgets/theme_switcher.dart';
import '../../settings/presentation/settings_screen.dart';
import '../domain/fill.dart';
import 'behavior_screen.dart';
import 'overview_screen.dart';
import 'rules_screen.dart';
import 'trades_screen.dart';

class DashboardScreen extends StatefulWidget {
  final WalletProfile wallet;
  final List<Fill> fills;

  const DashboardScreen({super.key, required this.wallet, required this.fills});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _walletStore = WalletLocalStore();
  final _client = HyperliquidClient();
  final _wsClient = HyperliquidWsClient();

  List<WalletProfile> _wallets = [];
  Map<String, List<Fill>> _fillsByAddress = {};
  String? _originAddress;

  int _selectedIndex = 0;
  Period _period = Period.all;
  bool _syncing = false;
  bool _live = false;
  List<RuleBreach> _recentBreaches = [];
  int _reconnectDelaySeconds = 2;
  Timer? _reconnectTimer;

  String get _activeAddress => widget.wallet.address;

  @override
  void initState() {
    super.initState();
    _fillsByAddress = {_activeAddress: widget.fills};
    _loadAllWallets();
    _startLiveSync();
    _loadRuleBreaches();
  }

  Future<void> _loadRuleBreaches() async {
    final rules = await RulesLocalStore(_activeAddress).loadAll();
    if (rules.isEmpty) {
      if (mounted) setState(() => _recentBreaches = []);
      return;
    }
    final breaches = RuleEvaluator().evaluate(rules, _displayedFills);
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final recent = breaches.where((b) => b.date.isAfter(cutoff)).toList();
    if (mounted) setState(() => _recentBreaches = recent);
  }

  Future<void> _loadAllWallets() async {
    final wallets = await _walletStore.loadWallets();
    final map = <String, List<Fill>>{};
    for (final w in wallets) {
      if (w.address.toLowerCase() == _activeAddress.toLowerCase()) {
        map[w.address] = widget.fills;
      } else {
        map[w.address] = await FillsLocalStore(w.address).loadAll();
      }
    }
    if (mounted) {
      setState(() {
        _wallets = wallets;
        _fillsByAddress = map;
      });
      _loadRuleBreaches();
    }
  }

  List<Fill> get _displayedFills {
    if (_originAddress == null) {
      return _fillsByAddress.values.expand((f) => f).toList();
    }
    return _fillsByAddress[_originAddress] ?? [];
  }

  void _startLiveSync() {
    _wsClient.subscribeUserFills(_activeAddress).listen(
      (fill) async {
        final store = FillsLocalStore(_activeAddress);
        final added = await store.mergeAndSave([fill]);
        if (added > 0) {
          final all = await store.loadAll();
          if (mounted) setState(() => _fillsByAddress[_activeAddress] = all);
          _loadRuleBreaches();
        }
        if (mounted && !_live) setState(() => _live = true);
        _reconnectDelaySeconds = 2;
      },
      onError: (_) {
        if (mounted) setState(() => _live = false);
        _scheduleReconnect();
      },
      onDone: () {
        if (mounted) setState(() => _live = false);
        _scheduleReconnect();
      },
    );
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: _reconnectDelaySeconds), () {
      if (!mounted) return;
      _reconnectDelaySeconds = (_reconnectDelaySeconds * 2).clamp(2, 30);
      _startLiveSync();
    });
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      final fetched = await _client.fetchUserFills(_activeAddress);
      final store = FillsLocalStore(_activeAddress);
      await store.mergeAndSave(fetched);
      final all = await store.loadAll();
      if (mounted) setState(() => _fillsByAddress[_activeAddress] = all);
      _loadRuleBreaches();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.syncErrorMessage)),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _wsClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeScope.themeOf(context);
    final l10n = AppLocalizations.of(context)!;
    final fills = _displayedFills;

    final screens = [
      OverviewScreen(
        fills: fills,
        period: _period,
        onPeriodChanged: (p) => setState(() => _period = p),
        wallets: _wallets,
        origin: _originAddress,
        onOriginChanged: (address) {
          setState(() => _originAddress = address);
          _loadRuleBreaches();
        },
        breachCount: _recentBreaches.length,
        onViewRules: () => setState(() => _selectedIndex = 3),
      ),
      TradesScreen(address: _activeAddress, fills: fills),
      BehaviorScreen(fills: fills),
      RulesScreen(address: _activeAddress, fills: fills),
    ];

    return Scaffold(
      backgroundColor: theme.background,
      body: Row(
        children: [
          AppSidebar(
            walletName: widget.wallet.name,
            selectedIndex: _selectedIndex,
            onSelect: (index) => setState(() => _selectedIndex = index),
            onSettingsTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Row(
                      children: [
                        if (_live) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: theme.positive, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(l10n.liveLabel, style: TextStyle(fontSize: 12, color: theme.textSecondary)),
                          const SizedBox(width: 16),
                        ],
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _syncing ? null : _syncNow,
                          icon: _syncing
                              ? SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: theme.textSecondary),
                                )
                              : Icon(Icons.sync, size: 16, color: theme.textSecondary),
                          label: Text(l10n.syncNowButton, style: TextStyle(color: theme.textSecondary)),
                        ),
                        const LanguageSwitcher(),
                        const ThemeSwitcher(),
                      ],
                    ),
                  ),
                  Expanded(child: screens[_selectedIndex]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
