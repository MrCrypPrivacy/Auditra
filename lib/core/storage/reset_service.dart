import 'package:path_provider/path_provider.dart';

class ResetService {
  Future<void> wipeAllData() async {
    final dir = await getApplicationSupportDirectory();
    if (await dir.exists()) {
      final entries = dir.listSync();
      for (final entry in entries) {
        await entry.delete(recursive: true);
      }
    }
  }
}
