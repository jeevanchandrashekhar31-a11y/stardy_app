import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/color_codes.dart';
import 'quiz_result_page.dart';
import '../../../features/courses/models/quiz_models.dart';
import '../../../features/courses/repository/quiz_repository.dart';
import '../../../core/network/api_client.dart';


class QuizPage extends ConsumerStatefulWidget {
  final QuizTarget target;

  const QuizPage({super.key, required this.target});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  int _currentIndex = 0;
  final Map<int, int> _selectedAnswers = {};
  final Set<int> _flagged = {};

  List<QuizQuestion>? _questions;
  bool _isLoading = true;
  String? _error;
  String? _attemptId;
  String? _startedAt;
  bool _isSubmitting = false;
  
  final String _startIdempotencyKey = const Uuid().v4();
  final String _submitIdempotencyKey = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _fetchQuiz();
  }

  Future<void> _fetchQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = ref.read(quizRepositoryProvider);
    final target = widget.target;
    
    Result result;
    if (target is ModuleQuiz) {
      result = await repo.getModuleQuizAttempt(target.moduleId, _startIdempotencyKey);
    } else if (target is AssignmentQuiz) {
      result = await repo.getAssignmentQuiz(target.assignmentId);
    } else {
      setState(() {
        _error = 'Unknown quiz target';
        _isLoading = false;
      });
      return;
    }

    if (!mounted) return;

    if (result is Ok) {
      setState(() {
        if (target is ModuleQuiz) {
          final res = (result as Ok).data as QuizAttemptStartResponse;
          _questions = res.questions;
          _attemptId = res.attemptId;
          _startedAt = res.startedAt;
        } else {
          _questions = (result as Ok).data as List<QuizQuestion>;
          _startedAt = DateTime.now().toUtc().toIso8601String();
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = (result as Err).error.message;
        _isLoading = false;
      });
    }
  }

  QuizQuestion get _currentQuestion => _questions![_currentIndex];

  void _next() {
    if (_questions != null && _currentIndex < _questions!.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _back() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _toggleFlag() {
    setState(() {
      if (_flagged.contains(_currentIndex)) {
        _flagged.remove(_currentIndex);
      } else {
        _flagged.add(_currentIndex);
      }
    });
  }

  Future<void> _submitQuiz() async {
    if (_questions == null || _isSubmitting) return;

    final unanswered = _questions!.length - _selectedAnswers.length;

    if (unanswered > 0) {
      final flaggedUnanswered = _flagged
          .where((i) => !_selectedAnswers.containsKey(i))
          .length;
      final message = StringBuffer(
        'You have $unanswered unanswered question${unanswered == 1 ? '' : 's'}.',
      );
      if (flaggedUnanswered > 0) {
        message.write(
          ' $flaggedUnanswered of them ${flaggedUnanswered == 1 ? 'is' : 'are'} flagged for review.',
        );
      }

      final shouldSubmit = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Submit quiz?'),
          content: Text(message.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep Reviewing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );

      if (shouldSubmit != true) return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final repo = ref.read(quizRepositoryProvider);
    final target = widget.target;
    
    final answers = _selectedAnswers.entries.map((e) {
      return {
        'questionId': _questions![e.key].id,
        'selectedIndex': e.value,
      };
    }).toList();

    Result result;
    if (target is ModuleQuiz) {
      if (_attemptId == null) {
        // Fallback if missing
        setState(() {
          _error = 'Attempt ID is missing.';
          _isSubmitting = false;
        });
        return;
      }
      result = await repo.submitModuleQuizAttempt(_attemptId!, _submitIdempotencyKey, answers);
    } else {
      result = await repo.submitAssignmentQuiz((target as AssignmentQuiz).assignmentId, _submitIdempotencyKey, answers, _startedAt);
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result is Ok<QuizOutcome>) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultPage(
            outcome: (result as Ok).data,
            title: widget.target.title,
          ),
        ),
      );
    } else {
      final err = (result as Err).error;
      if (err is ConflictFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already submitted this')),
        );
        Navigator.of(context).popUntil((route) => route.settings.name == '/course-details' || route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.message)),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (_isLoading) return true;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave quiz?'),
        content: const Text('Your progress will be saved and you can resume later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    
    return confirm ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (context.mounted && shouldPop) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (!context.mounted) return;
              if (shouldPop) {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(widget.target.title, style: const TextStyle(color: Colors.black)),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchQuiz,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_questions == null || _questions!.isEmpty) {
      return const Center(child: Text('No questions available'));
    }

    final isFlagged = _flagged.contains(_currentIndex);
    final selected = _selectedAnswers[_currentIndex];

    return SafeArea(
      child: Column(
        children: [
          // PROGRESS BAR
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions!.length,
            minHeight: 4,
            backgroundColor: Colors.black12,
            color: AppColors.primary,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // TOP ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(
                        Icons.notifications_none,
                        color: AppColors.primaryDark,
                      ),
                      Text(
                        '${_currentIndex + 1} / ${_questions!.length}',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.primaryDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // QUESTION
                  Text(
                    _currentQuestion.question,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // OPTIONS
                  ...List.generate(_currentQuestion.options.length, (index) {
                    final isSelected = selected == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          setState(
                            () => _selectedAnswers[_currentIndex] = index,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Text(
                                String.fromCharCode(65 + index),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _currentQuestion.options[index],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryDark
                                        : Colors.grey.shade400,
                                    width: 1.5,
                                  ),
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // BOTTOM NAV
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navButton(
                    icon: Icons.arrow_back,
                    label: 'Back',
                    iconFirst: true,
                    onTap: _currentIndex == 0 || _isSubmitting ? null : _back,
                  ),

                  GestureDetector(
                    onTap: _isSubmitting ? null : _toggleFlag,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 1.5),
                        color: isFlagged
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                      ),
                      child: const Icon(
                        Icons.flag_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ),

                  if (_isSubmitting)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: CircularProgressIndicator(),
                    )
                  else
                    _navButton(
                      icon: Icons.arrow_forward,
                      label: _currentIndex == _questions!.length - 1
                          ? 'Submit'
                          : 'Next',
                      iconFirst: false,
                      onTap: _currentIndex == _questions!.length - 1
                          ? _submitQuiz
                          : _next,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required String label,
    required bool iconFirst,
    required VoidCallback? onTap,
  }) {
    final iconWidget = Icon(icon, color: Colors.white, size: 18);
    final labelWidget = Text(
      label,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    );

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: iconFirst
                ? [iconWidget, const SizedBox(width: 8), labelWidget]
                : [labelWidget, const SizedBox(width: 8), iconWidget],
          ),
        ),
      ),
    );
  }
}
