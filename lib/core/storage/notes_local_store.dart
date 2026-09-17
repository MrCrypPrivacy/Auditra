import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class NotesLocalStore {
  final String address;

  NotesLocalStore(this.address);

  String get _fileName => 'notes_${address.toLowerCase()}.json';

  Future<File> _resolveFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<Map<String, String>> loadAll() async {
    final file = await _resolveFile();
    if (!await file.exists()) return {};
    final content = await file.readAsString();
    if (content.isEmpty) return {};
    final decoded = jsonDecode(content) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value as String));
  }

  Future<void> setNote(String tid, String note) async {
    final notes = await loadAll();
    if (note.trim().isEmpty) {
      notes.remove(tid);
    } else {
      notes[tid] = note.trim();
    }
    final file = await _resolveFile();
    await file.writeAsString(jsonEncode(notes));
  }
}
