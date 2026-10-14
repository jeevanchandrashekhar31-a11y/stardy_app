import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/gamification/repository/gamification_repository.dart';
import '../models/gamification_result.dart';
import '../../Views/CareerPath/level_up_page.dart';

void showProgressFeedback(BuildContext context, WidgetRef ref, GamificationResult? r) {
  if (r != null) {
    invalidateAfterProgress(ref.invalidate);
    if (r.leveledUp) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LevelUpPage(result: r),
        ),
      );
    } else if (r.xpAwarded > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('+${r.xpAwarded} XP'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
