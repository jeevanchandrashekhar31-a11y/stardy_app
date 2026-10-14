import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/color_codes.dart';
import '../../services/auth_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black12,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/profile_avatar.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Sai Sharan',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Ph No - +1 555-0100',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _settingsTile(
                context,
                icon: Icons.info_outline,
                title: 'Personal Information',
              ),
              _settingsTile(
                context,
                icon: Icons.wb_sunny_outlined,
                title: 'Theme',
                value: 'Light',
              ),
              _settingsTile(
                context,
                icon: Icons.language_outlined,
                title: 'Language',
                value: 'English (UK)',
              ),
              _settingsTile(
                context,
                icon: Icons.description_outlined,
                title: 'Terms and Conditions',
              ),
              _settingsTile(
                context,
                icon: Icons.info_outline,
                title: 'About Stardy',
              ),
              _settingsTile(
                context,
                icon: Icons.logout,
                title: 'Log Out',
                isDestructive: true,
                showChevron: false,
                onTap: () async {
                  try {
                    await AuthService.instance.signOut();
                  } catch (_) {
                    // No Firebase session to sign out of yet — still route
                    // the user out of the authenticated area below.
                  }
                  if (context.mounted) context.go('/auth');
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? value,
    bool isDestructive = false,
    bool showChevron = true,
    VoidCallback? onTap,
  }) {
    final color = isDestructive ? AppColors.primary : AppColors.textPrimary;

    return GestureDetector(
      onTap:
          onTap ??
          () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(title),
                duration: const Duration(seconds: 1),
              ),
            );
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value != null) ...[
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (showChevron)
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
