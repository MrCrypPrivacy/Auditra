import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../features/dashboard/domain/fill.dart';

class FillsLocalStore {
  final String address;

  FillsLocalStore(this.address);

  String get _fileName => 'fills_${address.toLowerCase()}.json';

  Future<File> _resolveFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<Fill>> loadAll() async {
    final file = await _resolveFile();
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    if (content.isEmpty) return [];

    final decoded = jsonDecode(content) as List<dynamic>;
    return decoded
        .map((raw) => Fill.fromJson(raw as Map<String, dynamic>))
        .toList();
  }

  Future<int> mergeAndSave(List<Fill> incoming) async {
    final existing = await loadAll();
    final existingIds = existing.map((fill) => fill.tid).toSet();

    final newFills =
        incoming.where((fill) => !existingIds.contains(fill.tid)).toList();

    if (newFills.isEmpty) return 0;

    final merged = [...existing, ...newFills]
      ..sort((a, b) => a.time.compareTo(b.time));

    final file = await _resolveFile();
    await file
        .writeAsString(jsonEncode(merged.map((f) => f.toJson()).toList()));

    return newFills.length;
  }

  Future<void> replaceAll(List<Fill> fills) async {
    final sorted = [...fills]..sort((a, b) => a.time.compareTo(b.time));
    final file = await _resolveFile();
    await file.writeAsString(jsonEncode(sorted.map((f) => f.toJson()).toList()));
  }
}
