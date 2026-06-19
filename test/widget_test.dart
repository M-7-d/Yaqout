import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakut/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: YakutApp()));
    await tester.pump(const Duration(seconds: 1));
    // App renders without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
