import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';

import '../../features/dashboard/domain/fill.dart';

class ExportImportService {
  Future<String?> exportFills(String address, List<Fill> fills) async {
    final location = await getSaveLocation(
      suggestedName: 'auditra-export-$address.json',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (location == null) return null;

    final jsonStr = jsonEncode(fills.map((f) => f.toJson()).toList());
    final file = File(location.path);
    await file.writeAsString(jsonStr);
    return location.path;
  }

  Future<String?> exportFillsCsv(String address, List<Fill> fills) async {
    final location = await getSaveLocation(
      suggestedName: 'auditra-export-$address.csv',
      acceptedTypeGroups: [
        const XTypeGroup(label: 'CSV', extensions: ['csv']),
      ],
    );
    if (location == null) return null;

    final buffer = StringBuffer();
    buffer.writeln(
      'coin,price,size,side,direction,time,closedPnl,fee,feeToken,tid,startPosition',
    );
    for (final f in fills) {
      buffer.writeln([
        f.coin,
        f.price,
        f.size,
        f.side,
        f.direction,
        f.time.toIso8601String(),
        f.closedPnl,
        f.fee,
        f.feeToken,
        f.tid,
        f.startPosition,
      ].join(','));
    }

    final file = File(location.path);
    await file.writeAsString(buffer.toString());
    return location.path;
  }

  Future<List<Fill>?> importFills() async {
    final file = await openFile(
      acceptedTypeGroups: [
        const XTypeGroup(label: 'JSON', extensions: ['json']),
      ],
    );
    if (file == null) return null;

    final content = await file.readAsString();
    final decoded = jsonDecode(content) as List<dynamic>;
    return decoded
        .map((raw) => Fill.fromJson(raw as Map<String, dynamic>))
        .toList();
  }
}
