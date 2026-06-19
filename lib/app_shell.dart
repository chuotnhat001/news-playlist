import 'package:flutter/material.dart';

import 'package:news_playlist/features/player/mini_player.dart';

class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: child),
        const MiniPlayer(),
      ],
    );
  }
}
