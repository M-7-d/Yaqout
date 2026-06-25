import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared/providers/shared_providers.dart';
import 'core/services/notification_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/storage/hive_storage_service.dart';
import 'core/storage/adapters/message_adapter.dart';
import 'core/storage/adapters/product_adapter.dart';
import 'core/storage/adapters/user_profile_adapter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file
  await dotenv.load(fileName: ".env");

  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(HiveMessageAdapter());
  Hive.registerAdapter(HiveProductAdapter());
  Hive.registerAdapter(HiveUserProfileAdapter());
  
  // Initialize Hive boxes
  final hiveStorage = HiveStorageService();
  await hiveStorage.initSettingsBox();
  await hiveStorage.initChatBox();
  await hiveStorage.initProductsBox();
  await hiveStorage.initUserProfileBox();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  final sharedPrefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
    ],
  );

  // Initialize Notification Service
  container.read(notificationServiceProvider).init();

  await SentryFlutter.init(
    (options) {
      // NOTE: Make sure to add SENTRY_DSN to your .env file
      options.dsn = dotenv.env['SENTRY_DSN'] ?? '';
      options.tracesSampleRate = 1.0;
    },
    appRunner: () => runApp(
      UncontrolledProviderScope(
        container: container,
        child: const YakutApp(),
      ),
    ),
  );
}
