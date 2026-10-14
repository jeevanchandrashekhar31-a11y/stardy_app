import 'package:flutter/material.dart';
import '../../core/config/feature_flags.dart';
import '../starbuddy/starbuddy_screen.dart';
import 'color_codes.dart';

/// Toggled by [StarbuddyScreen] so the bubble hides itself while its own
/// chat screen is on top.
final ValueNotifier<bool> chatbotFabVisible = ValueNotifier<bool>(true);

/// Floating Starbuddy shortcut. Drop this inside a [Stack] on the pages that
/// should offer it (Home, Opportunities, Profile) — not global to the app.
class StarbuddyFabButton extends StatelessWidget {
  const StarbuddyFabButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.starbuddy) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder<bool>(
      valueListenable: chatbotFabVisible,
      builder: (context, visible, _) {
        if (!visible) return const SizedBox.shrink();
        return Positioned(
          right: 16,
          // GlassNavbar sits at bottom:40 with height:65 (top edge at 105) —
          // clear it with room to spare, matching its fixed-offset style
          // rather than SafeArea (which double-counts the bottom inset here).
          bottom: 130,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const StarbuddyScreen()),
              );
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/starbuddy_avatar.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
