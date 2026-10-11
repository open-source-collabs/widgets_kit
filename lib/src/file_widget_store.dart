import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// Key/value data kept in one JSON file.
///
/// Used on Windows and Linux, where there is no shared preferences file for a widget to read.
/// The file is `widget_data.json` in [directory], so a native widget provider or any other
/// process can read the same values the app saved.
///
/// Reads and writes run one at a time, and a write replaces the file in one step, so a crash
/// cannot leave a half-written file behind.
class FileWidgetStore {
  /// Creates a store that keeps `widget_data.json` in [directory].
  FileWidgetStore(this.directory);

  /// Folder that holds the data file.
  final Directory directory;

  // Shared by every instance, because the plugin creates a store per call and the writes still
  // have to run one after another.
  static Future<void> _tail = Future<void>.value();

  File get _file => File('${directory.path}/widget_data.json');

  /// Stores [data] under [id], or removes [id] when [data] is `null`.
  ///
  /// Supports `bool`, `int`, `double` and `String`, the same types as the Android implementation.
  Future<bool> save(String id, Object? data) {
    if (data != null &&
        data is! bool &&
        data is! int &&
        data is! double &&
        data is! String) {
      return Future<bool>.error(
        PlatformException(
          code: '-10',
          message:
              'Invalid Type ${data.runtimeType}. Supported types are bool, int, double and String',
        ),
      );
    }
    return _serialized(() async {
      final values = await _read();
      if (data == null) {
        values.remove(id);
      } else {
        values[id] = data;
      }
      await directory.create(recursive: true);
      final temp = File('${_file.path}.tmp');
      await temp.writeAsString(jsonEncode(values), flush: true);
      await temp.rename(_file.path);
      return true;
    });
  }

  /// The value stored under [id], or `null` when there is none.
  Future<Object?> get(String id) =>
      _serialized(() async => (await _read())[id]);

  Future<Map<String, Object?>> _read() async {
    if (!await _file.exists()) {
      return <String, Object?>{};
    }
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is Map<String, dynamic>) {
        return Map<String, Object?>.of(decoded);
      }
    } on FormatException {
      // An unreadable file is treated as empty, and the next save replaces it.
    }
    return <String, Object?>{};
  }

  Future<T> _serialized<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }
}
