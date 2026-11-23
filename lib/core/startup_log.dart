import 'dart:io';

/// Catatan tahap-tahap startup ke file, supaya kalau app macet/hitam di PC
/// outlet kita bisa lihat berhenti di tahap mana (build release tidak punya
/// console). Ditulis ke `startup_log.txt` di sebelah exe; kalau folder itu
/// tidak bisa ditulis, fallback ke %TEMP%.
class StartupLog {
  StartupLog._();

  static File? _file;

  static File? _resolveFile() {
    if (_file != null) return _file;
    final candidates = <String>[
      File(Platform.resolvedExecutable).parent.path,
      Directory.systemTemp.path,
    ];
    for (final dir in candidates) {
      try {
        final f = File('$dir${Platform.pathSeparator}startup_log.txt');
        f.writeAsStringSync('', mode: FileMode.append, flush: true);
        return _file = f;
      } catch (_) {}
    }
    return null;
  }

  static void write(String message) {
    try {
      _resolveFile()?.writeAsStringSync(
        '${DateTime.now().toIso8601String()}  $message\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }
}
