import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:news_playlist/shared/widgets/empty_state.dart';

void main() {
  testWidgets('EmptyState renders icon, title, and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.article_outlined,
            title: 'No articles found',
            subtitle: 'Pull down to refresh',
          ),
        ),
      ),
    );

    expect(find.text('No articles found'), findsOneWidget);
    expect(find.text('Pull down to refresh'), findsOneWidget);
    expect(find.byIcon(Icons.article_outlined), findsOneWidget);
  });

  testWidgets('EmptyState shows action button when provided', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.error_outline,
            title: 'Error',
            actionLabel: 'Retry',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Retry'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(tapped, isTrue);
  });

  testWidgets('EmptyState hides subtitle when null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.article,
            title: 'Empty',
          ),
        ),
      ),
    );

    expect(find.text('Empty'), findsOneWidget);
    // Only title and icon, no subtitle text
  });
}
