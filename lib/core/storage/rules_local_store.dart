import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../rules/trade_rule.dart';

class RulesLocalStore {
  final String address;

  RulesLocalStore(this.address);

  String get _fileName => 'rules_${address.toLowerCase()}.json';

  Future<File> _resolveFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<TradeRule>> loadAll() async {
    final file = await _resolveFile();
    if (!await file.exists()) return [];
    final content = await file.readAsString();
    if (content.isEmpty) return [];
    final decoded = jsonDecode(content) as List<dynamic>;
    return decoded
        .map((raw) => TradeRule.fromJson(raw as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(TradeRule rule) async {
    final rules = await loadAll();
    rules.add(rule);
    await _save(rules);
  }

  Future<void> remove(String id) async {
    final rules = await loadAll();
    rules.removeWhere((r) => r.id == id);
    await _save(rules);
  }

  Future<void> _save(List<TradeRule> rules) async {
    final file = await _resolveFile();
    await file.writeAsString(jsonEncode(rules.map((r) => r.toJson()).toList()));
  }
}
