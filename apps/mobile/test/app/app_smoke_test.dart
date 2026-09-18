import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hesably/app/app.dart';
import 'package:hesably/app/router/app_router.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(HesablyApp(router: AppRouter()));
    await tester.pumpAndSettle();
  }

  testWidgets('app boots to the home shell with the bottom navigation', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('الرئيسية'), findsWidgets);
  });

  testWidgets('navigation switches between the four tabs', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('المعاملات'));
    await tester.pumpAndSettle();
    expect(find.text('المعاملات'), findsWidgets);

    await tester.tap(find.text('التقارير'));
    await tester.pumpAndSettle();
    expect(find.text('التقارير'), findsWidgets);

    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('الإعدادات'), findsWidgets);
  });
}
