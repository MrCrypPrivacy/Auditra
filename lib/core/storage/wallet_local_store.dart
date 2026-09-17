import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'wallet_profile.dart';

class WalletLocalStore {
  static const _fileName = 'wallets.json';

  Future<File> _resolveFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<Map<String, dynamic>> _readRaw() async {
    final file = await _resolveFile();
    if (!await file.exists()) return {'wallets': [], 'activeAddress': null};
    final content = await file.readAsString();
    if (content.isEmpty) return {'wallets': [], 'activeAddress': null};
    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<List<WalletProfile>> loadWallets() async {
    final raw = await _readRaw();
    final list = raw['wallets'] as List<dynamic>? ?? [];
    return list
        .map((e) => WalletProfile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String?> loadActiveAddress() async {
    final raw = await _readRaw();
    return raw['activeAddress'] as String?;
  }

  Future<void> addWallet(WalletProfile wallet, {bool makeActive = true}) async {
    final wallets = await loadWallets();
    final exists = wallets.any(
      (w) => w.address.toLowerCase() == wallet.address.toLowerCase(),
    );
    if (!exists) wallets.add(wallet);

    final active = makeActive ? wallet.address : await loadActiveAddress();
    await _save(wallets, active);
  }

  Future<void> setActive(String address) async {
    final wallets = await loadWallets();
    await _save(wallets, address);
  }

  Future<void> removeWallet(String address) async {
    final wallets = await loadWallets();
    wallets.removeWhere((w) => w.address.toLowerCase() == address.toLowerCase());

    final active = await loadActiveAddress();
    final stillActive = active?.toLowerCase() == address.toLowerCase();
    final nextActive = stillActive
        ? (wallets.isNotEmpty ? wallets.first.address : null)
        : active;

    await _save(wallets, nextActive);
  }

  Future<void> _save(List<WalletProfile> wallets, String? activeAddress) async {
    final file = await _resolveFile();
    await file.writeAsString(jsonEncode({
      'wallets': wallets.map((w) => w.toJson()).toList(),
      'activeAddress': activeAddress,
    }));
  }
}
