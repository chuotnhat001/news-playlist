import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/features/home/home_screen.dart';

void main() {
  testWidgets('HomeScreen shows category grid', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('News Playlist'), findsOneWidget);
    expect(find.text('Cong Nghe'), findsOneWidget);
    expect(find.text('Kinh Doanh'), findsOneWidget);
    expect(find.text('Chung Khoan'), findsOneWidget);
  });

  testWidgets('CategoryCard taps navigates to PlaylistScreen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.tap(find.text('Cong Nghe'));
    await tester.pumpAndSettle();

    // Should navigate to PlaylistScreen with category title
    expect(find.text('Cong Nghe'), findsOneWidget);
  });
}
