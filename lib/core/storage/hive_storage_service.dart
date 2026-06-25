import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/message_adapter.dart';
import 'adapters/product_adapter.dart';
import 'adapters/user_profile_adapter.dart';

class HiveStorageService {
  static const String _settingsBox = 'settings_box';
  static const String _chatBox = 'chat_box';
  static const String _productsBox = 'products_box';
  static const String _userProfileBox = 'user_profile_box';

  // Settings
  Future<void> initSettingsBox() async {
    await Hive.openBox(_settingsBox);
  }

  Future<void> setSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }

  Future<void> deleteSetting(String key) async {
    final box = Hive.box(_settingsBox);
    await box.delete(key);
  }

  // Chat Messages
  Future<void> initChatBox() async {
    await Hive.openBox(_chatBox);
  }

  Future<void> saveMessage(String roomId, HiveMessage message) async {
    final box = Hive.box(_chatBox);
    final key = 'messages_$roomId';
    final messages = box.get(key, defaultValue: <HiveMessage>[]) as List<HiveMessage>;
    
    // Remove if already exists to avoid duplicates
    messages.removeWhere((m) => m.id == message.id);
    messages.add(message);
    
    await box.put(key, messages);
  }

  List<HiveMessage> getMessages(String roomId) {
    final box = Hive.box(_chatBox);
    final key = 'messages_$roomId';
    return box.get(key, defaultValue: <HiveMessage>[]) as List<HiveMessage>;
  }

  Future<void> clearMessages(String roomId) async {
    final box = Hive.box(_chatBox);
    final key = 'messages_$roomId';
    await box.delete(key);
  }

  // Products
  Future<void> initProductsBox() async {
    await Hive.openBox(_productsBox);
  }

  Future<void> saveRecentProduct(HiveProduct product) async {
    final box = Hive.box(_productsBox);
    final recentProducts = box.get('recent', defaultValue: <HiveProduct>[]) as List<HiveProduct>;
    
    // Remove if already exists to move to top
    recentProducts.removeWhere((p) => p.id == product.id);
    recentProducts.insert(0, product);
    
    // Keep only last 20 products
    if (recentProducts.length > 20) {
      recentProducts.removeRange(20, recentProducts.length);
    }
    
    await box.put('recent', recentProducts);
  }

  List<HiveProduct> getRecentProducts() {
    final box = Hive.box(_productsBox);
    return box.get('recent', defaultValue: <HiveProduct>[]) as List<HiveProduct>;
  }

  Future<void> clearRecentProducts() async {
    final box = Hive.box(_productsBox);
    await box.delete('recent');
  }

  // User Profile
  Future<void> initUserProfileBox() async {
    await Hive.openBox(_userProfileBox);
  }

  Future<void> saveUserProfile(HiveUserProfile profile) async {
    final box = Hive.box(_userProfileBox);
    await box.put('profile', profile);
  }

  HiveUserProfile? getUserProfile() {
    final box = Hive.box(_userProfileBox);
    return box.get('profile');
  }

  Future<void> clearUserProfile() async {
    final box = Hive.box(_userProfileBox);
    await box.delete('profile');
  }

  // Clear all data
  Future<void> clearAll() async {
    await Hive.box(_settingsBox).clear();
    await Hive.box(_chatBox).clear();
    await Hive.box(_productsBox).clear();
    await Hive.box(_userProfileBox).clear();
  }
}
