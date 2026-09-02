import 'dart:convert';
import 'dart:io';

import 'package:cleanbox/common/path.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Stores SharedPreferences inside the app's `config` directory (portable
/// layout) instead of the platform's %APPDATA% location.
class ConfigFilePreferencesStore extends SharedPreferencesStorePlatform {
  static void install() {
    if (SharedPreferencesStorePlatform.instance
        is! ConfigFilePreferencesStore) {
      SharedPreferencesStorePlatform.instance = ConfigFilePreferencesStore();
    }
  }

  Future<File> _file() async {
    return File(await appPath.sharedPreferencesPath);
  }

  @override
  Future<Map<String, Object>> getAll() async {
    final file = await _file();
    if (!await file.exists()) {
      return <String, Object>{};
    }
    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded.cast<String, Object>();
      }
    } catch (_) {
      // Corrupted file: fall back to empty preferences.
    }
    return <String, Object>{};
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    final map = await getAll();
    map[key] = value;
    return _write(map);
  }

  @override
  Future<bool> remove(String key) async {
    final map = await getAll();
    if (map.remove(key) == null) {
      return false;
    }
    return _write(map);
  }

  @override
  Future<bool> clear() async {
    return _write(<String, Object>{});
  }

  Future<bool> _write(Map<String, Object> map) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(map));
      return true;
    } catch (_) {
      return false;
    }
  }
}