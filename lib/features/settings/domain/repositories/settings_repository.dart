abstract class SettingsRepository {
  Future<void> setBool(String key, bool value);
  bool getBool(String key, {bool defaultValue = true});

  Future<void> setString(String key, String value);
  String getString(String key, {String defaultValue = ''});

  Future<void> setStringList(String key, List<String> value);
  List<String> getStringList(String key);
}
