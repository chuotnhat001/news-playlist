import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/pump_helpers.dart';
import '../helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Settings flow', () {
    testWidgets('navigate to settings via icon', (tester) async {
      final app = await createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.text('Cấu hình danh mục'), findsOneWidget);
    });

    testWidgets('add category with valid URL', (tester) async {
      final app = await createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Test News',
      );
      await tester.enterText(
        find.byType(TextField).last,
        'https://soha.vn/test-news.htm',
      );

      await tester.tap(find.text('Thêm danh mục'));
      await tester.pumpAndSettle();

      expect(find.text('Test News'), findsOneWidget);
    });

    testWidgets('add category shows error for empty fields', (tester) async {
      final app = await createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Thêm danh mục'));
      await tester.pumpAndSettle();

      expect(
        find.text('Vui lòng nhập đầy đủ tên và URL'),
        findsOneWidget,
      );
    });

    testWidgets('add category shows error for non-https URL', (tester) async {
      final app = await createTestApp();
      await tester.pumpWidget(app);
      await tester.pumpUntilReady();

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Bad URL');
      await tester.enterText(
        find.byType(TextField).last,
        'http://example.com/news',
      );

      await tester.tap(find.text('Thêm danh mục'));
      await tester.pumpAndSettle();

      expect(
        find.text('URL phải bắt đầu bằng https://'),
        findsOneWidget,
      );
    });
  });
}
