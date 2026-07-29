import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tarazyar/authentication/presentation/pages/login_page.dart';

void main() {
  testWidgets('LoginPage renders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ورود به ترازیار'), findsOneWidget);
  });
}