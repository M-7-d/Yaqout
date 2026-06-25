import '../../../../core/storage/hive_storage_service.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final HiveStorageService _hiveStorage;
  SettingsRepositoryImpl(this._hiveStorage);

  @override
  Future<void> setBool(String key, bool value) async {
    await _hiveStorage.setSetting(key, value);
  }

  @override
  bool getBool(String key, {bool defaultValue = true}) {
    return _hiveStorage.getSetting(key, defaultValue: defaultValue) as bool? ?? defaultValue;
  }

  @override
  Future<void> setString(String key, String value) async {
    await _hiveStorage.setSetting(key, value);
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    return _hiveStorage.getSetting(key, defaultValue: defaultValue) as String? ?? defaultValue;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    await _hiveStorage.setSetting(key, value);
  }

  @override
  List<String> getStringList(String key) {
    return _hiveStorage.getSetting(key, defaultValue: <String>[]) as List<String>? ?? [];
  }
}
