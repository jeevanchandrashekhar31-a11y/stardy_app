import 'dart:ui';
import 'package:flutter/material.dart';

class GlassNavbar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const GlassNavbar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 80,
      right: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10), // light transparent
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.25), // top shine
                  Colors.white.withValues(alpha: 0.05), // bottom fade
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home, 0),
                _navItem(Icons.menu_book, 1),
                _navItem(Icons.work, 2),
                _navItem(Icons.person, 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, int index) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? Colors.white : Colors.black54,
        ),
      ),
    );
  }
}
