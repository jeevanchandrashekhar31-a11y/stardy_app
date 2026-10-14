import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/color_codes.dart';
import '../../../core/network/api_client.dart';
import '../../../features/remedial/models/remedial_models.dart';
import '../../../features/remedial/repository/remedial_repository.dart';

class RemedialQuizPage extends ConsumerStatefulWidget {
  final String assignmentSubmissionId;

  const RemedialQuizPage({super.key, required this.assignmentSubmissionId});

  @override
  ConsumerState<RemedialQuizPage> createState() => _RemedialQuizPageState();
}

class _RemedialQuizPageState extends ConsumerState<RemedialQuizPage> {
  int _currentIndex = 0;
  int? _selectedIndex;
  bool _showWrong = false;
  bool _revealing = false;

  bool _isLoading = true;
  String? _error;
  RemedialQuiz? _quiz;

  final List<Map<String, dynamic>> _submittedAnswers = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _generateQuiz();
  }

  Future<void> _generateQuiz() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final repo = ref.read(remedialRepositoryProvider);
    final res = await repo.generate(widget.assignmentSubmissionId);

    if (!mounted) return;

    if (res is Ok<RemedialQuiz>) {
      setState(() {
        _quiz = res.data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = (res as Err).error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _submitQuiz() async {
    if (_quiz == null) return;
    setState(() {
      _isSubmitting = true;
    });

    final repo = ref.read(remedialRepositoryProvider);
    final res = await repo.submit(_quiz!.remedialQuizId, _submittedAnswers);

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    if (res is Ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remedial completed!')),
      );
      Navigator.of(context).popUntil(
          (route) => route.settings.name == '/course-details' || route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((res as Err).error.message)),
      );
    }
  }

  RemedialQuestion get _current => _quiz!.questions[_currentIndex];
  bool get _isLastQuestion => _currentIndex == _quiz!.questions.length - 1;

  void _selectOption(int index) {
    setState(() {
      _selectedIndex = index;
      _showWrong = false;
    });
  }

  void _showHint() {
    if (_current.explanation == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_current.explanation!)),
    );
  }

  void _onPrimaryButtonTap() {
    if (_showWrong) {
      setState(() {
        _showWrong = false;
        _selectedIndex = null;
      });
      return;
    }

    if (_selectedIndex == null) return;

    // Record their first attempt for this question if not already recorded
    final bool alreadyAnswered = _submittedAnswers.any((a) => a['questionId'] == _current.id);
    if (!alreadyAnswered) {
      _submittedAnswers.add({
        'questionId': _current.id,
        'selectedIndex': _selectedIndex,
      });
    }

    if (_selectedIndex == _current.correctIndex) {
      setState(() => _revealing = true);
    } else {
      setState(() => _showWrong = true);
    }
  }

  void _goToNextQuestion() {
    if (_isLastQuestion) {
      _submitQuiz();
      return;
    }

    setState(() {
      _currentIndex++;
      _selectedIndex = null;
      _showWrong = false;
      _revealing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.7),
            radius: 1.3,
            colors: [Color(0xFFF7D9D9), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!_isLoading && _error == null && !_revealing) ...[
                    const SizedBox(height: 12),
                    const Text(
                      "Don't worry\nYou've Got this !",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: SizedBox(
                          width: 320,
                          child: _buildMainContent(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_isSubmitting)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 24),
            Text(
              'Building your practice quiz...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generateQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    if (_quiz == null || _quiz!.questions.isEmpty) {
      return const Center(child: Text("No questions available."));
    }

    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        _ghostCard(rotation: -0.045, dx: 16, dy: 18),
        _ghostCard(rotation: 0.04, dx: -14, dy: 26),
        _ghostCard(rotation: -0.02, dx: 6, dy: 34),
        _revealing ? _buildRevealCard() : _buildQuestionCard(),
      ],
    );
  }

  Widget _ghostCard({
    required double rotation,
    required double dx,
    required double dy,
  }) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 300,
          height: 420,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard() {
    final total = _quiz!.questions.length;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(total, (i) {
              final filled = i <= _currentIndex;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                  height: 4,
                  decoration: BoxDecoration(
                    color: filled ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Text(
            'Q ${(_currentIndex + 1).toString().padLeft(2, '0')}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            _current.question,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(_current.options.length, (index) {
            final isSelected = _selectedIndex == index;
            final isWrong = isSelected && _showWrong;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => _selectOption(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isWrong ? AppColors.primary : Colors.grey.shade300,
                      width: isWrong ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        String.fromCharCode(65 + index),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _current.options[index],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (isWrong)
                        const Icon(
                          Icons.cancel,
                          color: AppColors.primary,
                          size: 20,
                        )
                      else
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.grey.shade400,
                              width: 1.5,
                            ),
                            color: isSelected
                                ? Colors.black
                                : Colors.transparent,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _showHint,
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.black54,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Hint',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _onPrimaryButtonTap,
                child: Opacity(
                  opacity: (_selectedIndex == null && !_showWrong) ? 0.4 : 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _showWrong ? 'Retry' : 'Next',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevealCard() {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Correct Answer',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            'Option ${String.fromCharCode(65 + _current.correctIndex)} : '
            '${_current.options[_current.correctIndex]}',
            style: const TextStyle(
              color: Colors.green,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          if (_current.explanation != null)
            Text(
              _current.explanation!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goToNextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isLastQuestion ? 'Finish' : 'Next',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
