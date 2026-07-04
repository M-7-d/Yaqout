import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakut/app.dart';
import 'package:yakut/features/auth/domain/repositories/auth_repository.dart';
import 'package:yakut/features/auth/presentation/providers/auth_provider.dart';
import 'package:yakut/core/services/notification_service.dart';
import 'package:yakut/features/auth/domain/entities/user_entity.dart';

class FakeAuthRepository implements AuthRepository {
  const FakeAuthRepository();

  @override
  Future<UserEntity?> getCurrentUser() async => null;

  @override
  Stream<UserEntity?> get authStateChanges => Stream.value(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNotificationService implements NotificationService {
  const FakeNotificationService();

  @override
  void init() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(const FakeAuthRepository()),
          notificationServiceProvider.overrideWithValue(const FakeNotificationService()),
        ],
        child: const YakutApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    // App renders without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
