import 'package:flutter/material.dart';
import '../../../core/ui/error_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../../features/grades/models/grade_models.dart';
import '../../../features/grades/providers/grades_provider.dart';
import '../../../core/config/feature_flags.dart';

class GradesPage extends ConsumerStatefulWidget {
  final String? courseId;
  const GradesPage({super.key, this.courseId});

  @override
  ConsumerState<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends ConsumerState<GradesPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(gradesProvider(widget.courseId).notifier).fetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradesState = ref.watch(gradesProvider(widget.courseId));

    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body: gradesState.when(
        data: (state) {
          if (state.items.isEmpty) {
            return _buildEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () => ref.read(gradesProvider(widget.courseId).notifier).refresh(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0) + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 8, top: 10),
                    child: Text(
                      "Grades",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                
                final itemIndex = index - 1;
                
                if (itemIndex >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final item = state.items[itemIndex];
                return _buildGradeCard(context, item);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorView(
          message: safeErrorText(err),
          onRetry: () => ref.read(gradesProvider(widget.courseId).notifier).refresh(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_edu, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No graded work yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeCard(BuildContext context, GradeItem item) {
    Color color = Colors.green;
    if (item.percentage < 60) {
      color = Colors.red;
    } else if (item.percentage < 80) {
      color = Colors.orange;
    }

    final dt = item.submittedAt.toLocal();
    final formattedDate = "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssignmentResultPage(
              title: item.title,
              percentage: item.percentage,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 80,
                  width: 80,
                  child: CircularProgressIndicator(
                    value: item.percentage / 100,
                    strokeWidth: 8,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Text(
                  "${item.percentage}%",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text(
                        "Grade : ",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.letter ?? '-',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Submitted: $formattedDate",
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  if (widget.courseId == null) ...[
                    const SizedBox(height: 4),
                    Text(
                      item.courseTitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// RESULT PAGE
// =========================================================

class AssignmentResultPage extends StatelessWidget {
  final String title;
  final int percentage;

  const AssignmentResultPage({
    super.key,
    required this.title,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Score: $percentage%",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Marks Obtained: ${(percentage / 10).round()}/10",
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            if (FeatureFlags.answerReview) ...[
              const SizedBox(height: 30),
              const Text(
                "Questions Review",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _questionTile(
                question: "What is Flutter?",
                userAnswer: "Programming Language",
                correctAnswer: "UI Toolkit",
                isCorrect: false,
              ),
              const SizedBox(height: 16),
              _questionTile(
                question: "Which language Flutter uses?",
                userAnswer: "Dart",
                correctAnswer: "Dart",
                isCorrect: true,
              ),
              const SizedBox(height: 16),
              _questionTile(
                question: "Widget used for scrolling list?",
                userAnswer: "ListView",
                correctAnswer: "ListView",
                isCorrect: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // QUESTION TILE
  // =========================================================

  Widget _questionTile({
    required String question,
    required String userAnswer,
    required String correctAnswer,
    required bool isCorrect,
  }) {
    return ExpansionTile(
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      trailing: Icon(
        isCorrect ? Icons.check_circle : Icons.cancel,
        color: isCorrect ? Colors.green : Colors.red,
      ),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Answer: ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Text(
                userAnswer,
                style: TextStyle(
                  color: isCorrect ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Correct Answer: ",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Text(
                correctAnswer,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
