import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpHelpers on WidgetTester {
  Future<void> pumpUntilReady() async {
    await pumpAndSettle(const Duration(seconds: 2));
  }

  Future<void> pumpFrames(int count) async {
    for (var i = 0; i < count; i++) {
      await pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> pumpFor(Duration duration) async {
    await pump(duration);
    await pumpAndSettle();
  }
}

Finder findByText(String text) => find.text(text);

Finder findByIcon(IconData icon) => find.byIcon(icon);
