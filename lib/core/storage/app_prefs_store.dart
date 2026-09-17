import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AppPrefsStore {
  static const _fileName = 'app_prefs.json';

  Future<File> _resolveFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<Map<String, dynamic>> load() async {
    final file = await _resolveFile();
    if (!await file.exists()) return {};
    final content = await file.readAsString();
    if (content.isEmpty) return {};
    return jsonDecode(content) as Map<String, dynamic>;
  }

  Future<void> save(Map<String, dynamic> prefs) async {
    final file = await _resolveFile();
    await file.writeAsString(jsonEncode(prefs));
  }
}
