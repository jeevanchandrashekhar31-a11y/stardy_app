import 'package:flutter/material.dart';
import '../../Views/widgets/color_codes.dart';

class EmptyView extends StatelessWidget {
  final String message;
  final IconData? icon;

  const EmptyView({super.key, required this.message, this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              color: AppColors.textSecondary.withAlpha(128),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
