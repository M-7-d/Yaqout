import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  bool _isInitialized = false;

  /// Initializes OneSignal and sets up listeners.
  /// Safe to call multiple times.
  void init() {
    if (_isInitialized) return;

    final oneSignalAppId = dotenv.env['ONESIGNAL_APP_ID'];
    if (oneSignalAppId == null || oneSignalAppId.isEmpty) {
      debugPrint('NotificationService: ONESIGNAL_APP_ID is missing in .env');
      return;
    }

    // Set log level for debugging
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize OneSignal
    OneSignal.initialize(oneSignalAppId);

    // Request permissions
    OneSignal.Notifications.requestPermission(true);

    // Setup click listener
    OneSignal.Notifications.addClickListener((event) {
      final additionalData = event.notification.additionalData;
      _handleNotificationClick(additionalData);
    });

    _isInitialized = true;
  }

  /// Maps the backend user ID to OneSignal for targeted pushes.
  void loginUser(String userId) {
    if (!_isInitialized) return;
    OneSignal.login(userId);
  }

  /// Removes the user mapping from OneSignal.
  void logoutUser() {
    if (!_isInitialized) return;
    OneSignal.logout();
  }

  /// Updates OneSignal tags for segmenting notifications
  void updateTag(String key, String value) {
    if (!_isInitialized) return;
    OneSignal.User.addTagWithKey(key, value);
  }

  /// Disables or enables push notifications globally
  void setPushSubscriptionEnabled(bool enabled) {
    if (!_isInitialized) return;
    if (enabled) {
      OneSignal.User.pushSubscription.optIn();
    } else {
      OneSignal.User.pushSubscription.optOut();
    }
  }

  void _handleNotificationClick(Map<String, dynamic>? data) {
    if (data == null) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('NotificationService: rootNavigatorKey.currentContext is null. Cannot navigate.');
      return;
    }

    final type = data['type'] as String?;
    if (type == 'chat') {
      final roomId = data['roomId'] as String?;
      if (roomId != null) {
        context.go('/chat/$roomId');
      }
    } else if (type == 'live') {
      final streamId = data['streamId'] as String?;
      if (streamId != null) {
        context.go('/live/$streamId');
      }
    } else if (type == 'product') {
      final productId = data['productId'] as String?;
      if (productId != null) {
        context.go('/products/$productId');
      }
    }
  }
}
