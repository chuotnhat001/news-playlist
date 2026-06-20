import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:news_playlist/main.dart';

void main() {
  testWidgets('App renders loading state initially', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NewsPlaylistApp()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
