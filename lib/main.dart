import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/startup_log.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
    if (isDesktop) {
      StartupLog.write('=== start ${Platform.operatingSystemVersion}');
      FlutterError.onError = (details) {
        StartupLog.write('FlutterError: ${details.exceptionAsString()}\n${details.stack}');
        FlutterError.presentError(details);
      };
    }

    // Setup window dibatasi waktunya dan error-nya ditangkap: kalau plugin
    // window_manager macet di PC tertentu, app tetap lanjut ke runApp()
    // alih-alih diam di window hitam.
    if (isDesktop) {
      try {
        StartupLog.write('windowManager.ensureInitialized');
        await windowManager.ensureInitialized().timeout(const Duration(seconds: 5));
        StartupLog.write('windowManager.waitUntilReadyToShow');
        await windowManager
            .waitUntilReadyToShow(const WindowOptions(), () async {
              await windowManager.maximize();
              await windowManager.show();
              await windowManager.focus();
            })
            .timeout(const Duration(seconds: 5));
        StartupLog.write('window ready');
      } catch (e, st) {
        StartupLog.write('window setup gagal/timeout: $e\n$st');
      }
    }

    StartupLog.write('runApp');
    runApp(const ProviderScope(child: BillingApp()));

    if (isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        StartupLog.write('frame pertama tergambar');
        // Pastikan window tetap tampil & maximize kalau setup di atas timeout.
        windowManager.maximize().catchError((_) {});
        windowManager.show().catchError((_) {});
      });
    }
  }, (error, stack) {
    StartupLog.write('Uncaught: $error\n$stack');
  });
}
