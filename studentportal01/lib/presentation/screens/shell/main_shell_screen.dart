import 'package:flutter/material.dart';
import '../../widgets/bubble_nav_bar.dart';

class MainShellScreen extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const MainShellScreen({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: BubbleNavBar(currentIndex: currentIndex),
    );
  }
}
