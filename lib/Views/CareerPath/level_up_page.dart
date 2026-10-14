import 'package:flutter/material.dart';
import '../widgets/color_codes.dart';
import '../../core/models/gamification_result.dart';

class LevelUpPage extends StatelessWidget {
  final VoidCallback? onContinue;
  final GamificationResult result;

  const LevelUpPage({super.key, this.onContinue, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffEDEDED),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.black),
                ),
              ),
              const Spacer(),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.hexagon,
                      size: 110,
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                    const Icon(
                      Icons.hexagon,
                      size: 96,
                      color: AppColors.primaryDark,
                    ),
                    Text(
                      (result.newLevel ?? result.level).toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'LEVEL UP!',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 20,
                children: [
                  ...result.badgesUnlocked.map((b) => _rewardTile(
                        icon: Icons.shield_outlined,
                        iconColor: AppColors.primary,
                        label: 'Badge',
                        sublabel: b.name,
                      )),
                  if (result.xpAwarded > 0)
                    _rewardTile(
                      icon: Icons.bolt,
                      iconColor: Colors.white,
                      iconBg: AppColors.primary,
                      label: '+${result.xpAwarded}',
                      sublabel: 'XP Earned',
                    ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      onContinue ??
                      () {
                        Navigator.of(
                          context,
                        ).popUntil(ModalRoute.withName('/module-list'));
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sharing isn\'t available in this demo yet',
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Share the News',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bolt,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            '+250',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rewardTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String sublabel,
    Color? iconBg,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconBg,
            border: iconBg == null
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          sublabel,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
