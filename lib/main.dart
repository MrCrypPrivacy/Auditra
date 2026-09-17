import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/app_window_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const options = WindowOptions(
    size: Size(1200, 800),
    minimumSize: Size(900, 600),
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.addListener(AppWindowListener());
  await windowManager.setPreventClose(true);

  windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const AuditraApp());
}
