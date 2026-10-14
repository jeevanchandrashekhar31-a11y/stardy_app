import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/color_codes.dart';
import 'remedial_quiz_page.dart';
import '../../../features/courses/models/quiz_models.dart';
import '../../../core/ui/progress_feedback.dart';

class QuizResultPage extends ConsumerStatefulWidget {
  final QuizOutcome outcome;
  final String title;

  const QuizResultPage({
    super.key,
    required this.outcome,
    this.title = 'this course',
  });

  @override
  ConsumerState<QuizResultPage> createState() => _QuizResultPageState();
}

class _QuizResultPageState extends ConsumerState<QuizResultPage> {
  @override
  Widget build(BuildContext context) {
    final outcome = widget.outcome;
    final correct = outcome.correctCount;
    final total = outcome.totalCount;
    final percentage = outcome.score; // the server provides score 0-100

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'You got $correct/$total Right',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const Text(
                'Congratulations you scored',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                '$percentage %',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Image.asset(
                'assets/images/icon_trophy.png',
                width: 72,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.emoji_events,
                  size: 72,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Share your score',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (outcome.remedialEligible) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RemedialQuizPage(
                            assignmentSubmissionId: outcome.submissionId ?? '',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Practice Weak Areas',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (outcome.gamification != null) {
                      showProgressFeedback(context, ref, outcome.gamification!);
                    }
                    Navigator.of(
                      context,
                    ).popUntil((route) => route.settings.name == '/course-details' || route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Back to course',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
