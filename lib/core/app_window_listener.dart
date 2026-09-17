import 'dart:io';

import 'package:window_manager/window_manager.dart';

class AppWindowListener extends WindowListener {
  @override
  void onWindowClose() {
    exit(0);
  }
}
