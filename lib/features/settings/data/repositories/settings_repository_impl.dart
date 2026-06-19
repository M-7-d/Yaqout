import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _prefs;
  SettingsRepositoryImpl(this._prefs);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  bool getBool(String key, {bool defaultValue = true}) => _prefs.getBool(key) ?? defaultValue;

  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  @override
  String getString(String key, {String defaultValue = ''}) => _prefs.getString(key) ?? defaultValue;

  @override
  Future<void> setStringList(String key, List<String> value) => _prefs.setStringList(key, value);

  @override
  List<String> getStringList(String key) => _prefs.getStringList(key) ?? [];
}
