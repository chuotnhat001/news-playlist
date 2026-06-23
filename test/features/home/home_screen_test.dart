import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:news_playlist/features/home/widgets/category_card.dart';

void main() {
  testWidgets('CategoryCard shows formatted category name', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryCard(
            category: 'cong-nghe',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Cong Nghe'), findsOneWidget);
    expect(find.byIcon(Icons.computer), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('CategoryCard tap triggers onTap callback', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryCard(
            category: 'kinh-doanh',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Kinh Doanh'));
    expect(tapped, isTrue);
  });

  testWidgets('CategoryCard swipe left reveals Reload and Delete actions',
      (tester) async {
    bool reloaded = false;
    bool deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryCard(
            category: 'cong-nghe',
            onTap: () {},
            onReload: () => reloaded = true,
            onDelete: () => deleted = true,
          ),
        ),
      ),
    );

    await tester.drag(find.byType(CategoryCard), const Offset(-150, 0));
    await tester.pumpAndSettle();

    expect(find.text('Reload'), findsOneWidget);
    expect(find.text('Xóa'), findsOneWidget);

    await tester.tap(find.text('Reload'));
    await tester.pumpAndSettle();
    expect(reloaded, isTrue);
  });

  testWidgets('CategoryCard swipe left then tap Delete', (tester) async {
    bool deleted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryCard(
            category: 'cong-nghe',
            onTap: () {},
            onDelete: () => deleted = true,
          ),
        ),
      ),
    );

    await tester.drag(find.byType(CategoryCard), const Offset(-150, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });

  testWidgets('CategoryCard tap when actions visible closes actions',
      (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryCard(
            category: 'cong-nghe',
            onTap: () => tapped = true,
            onReload: () {},
            onDelete: () {},
          ),
        ),
      ),
    );

    await tester.drag(find.byType(CategoryCard), const Offset(-150, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cong Nghe'));
    await tester.pumpAndSettle();

    expect(tapped, isFalse);
  });
}
