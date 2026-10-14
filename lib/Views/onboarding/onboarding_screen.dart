import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/Views/widgets/color_codes.dart';
import '../../features/onboarding/onboarding_form.dart';
import '../../features/onboarding/onboarding_controller.dart';
import '../../features/session/session_controller.dart';
import '../../core/network/api_client.dart';

enum OnboardingPageType {
  intro,
  career,
  purpose,
  howHeard,
  influencer,
  expectation,
  similarApps,
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  late final TextEditingController _goalController;
  late final TextEditingController _influencerNameController;
  late final TextEditingController _referralCodeController;
  late final TextEditingController _achieveController;
  late final TextEditingController _experienceController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.86);

    final initialState = ref.read(onboardingFormProvider);
    _goalController = TextEditingController(text: initialState.careerGoal);
    _influencerNameController = TextEditingController(text: initialState.influencerName);
    _referralCodeController = TextEditingController(text: initialState.referralCodeUsed);
    _achieveController = TextEditingController(text: initialState.expectation);
    _experienceController = TextEditingController(text: initialState.similarAppsExperience);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _goalController.dispose();
    _influencerNameController.dispose();
    _referralCodeController.dispose();
    _achieveController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  List<OnboardingPageType> _getPagesList(OnboardingFormState state) {
    final list = [
      OnboardingPageType.intro,
      OnboardingPageType.career,
      OnboardingPageType.purpose,
      OnboardingPageType.howHeard,
    ];
    if (state.howHeard == OnboardingHowHeard.influencer) {
      list.add(OnboardingPageType.influencer);
    }
    list.addAll([
      OnboardingPageType.expectation,
      OnboardingPageType.similarApps,
    ]);
    return list;
  }

  bool _isCurrentPageValid(OnboardingFormState state) {
    final pages = _getPagesList(state);
    if (_currentPage < 0 || _currentPage >= pages.length) return false;
    final currentPageType = pages[_currentPage];

    switch (currentPageType) {
      case OnboardingPageType.intro:
        return true;
      case OnboardingPageType.career:
        return state.validateCareerGoal() == null;
      case OnboardingPageType.purpose:
        return state.validatePurpose() == null;
      case OnboardingPageType.howHeard:
        return state.validateHowHeard() == null;
      case OnboardingPageType.influencer:
        return state.validateInfluencerName() == null &&
            state.validateReferralCode() == null;
      case OnboardingPageType.expectation:
        return state.validateExpectation() == null;
      case OnboardingPageType.similarApps:
        return state.validateSimilarAppsExperience() == null;
    }
  }

  void _goToPage(int page, OnboardingFormState state) {
    final pages = _getPagesList(state);
    if (page < 0 || page >= pages.length) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildProgressDots(OnboardingFormState state) {
    final pages = _getPagesList(state);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(pages.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(right: 6),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryDark
                : AppColors.primaryDark.withValues(
                    alpha: _currentPage == 0 ? 0.4 : 0.2,
                  ),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildNavButtons(OnboardingFormState state) {
    final pages = _getPagesList(state);
    final isValid = _isCurrentPageValid(state);
    final isLastPage = _currentPage == pages.length - 1;

    final submitState = ref.watch(onboardingSubmitProvider);
    final isSubmitting = submitState is AsyncLoading;

    String? errorMessage;
    String finishText = 'Finish';
    if (submitState is AsyncError) {
      final error = submitState.error;
      if (error is RateLimitedFailure) {
        errorMessage = 'Please wait ${error.retryAfter ?? 60} seconds before retrying.';
        finishText = 'Wait';
      } else if (error is NetworkFailure || error is TimeoutFailure) {
        errorMessage = 'Network error. Please check your connection.';
        finishText = 'Retry';
      } else if (error is ApiFailure) {
        errorMessage = error.message;
        finishText = 'Retry';
      } else {
        errorMessage = 'An unexpected error occurred.';
        finishText = 'Retry';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildProgressDots(state),
        const SizedBox(height: 20),
        if (errorMessage != null && isLastPage)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              errorMessage,
              style: const TextStyle(color: AppColors.primary, fontSize: 14),
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _TapScale(
              onTap: isSubmitting ? null : () => _goToPage(_currentPage - 1, state),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == 0
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.background,
                  border: Border.all(
                    color: _currentPage == 0
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.black12,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: _currentPage == 0
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppColors.primaryDark,
                  size: 22,
                ),
              ),
            ),
            if (!isLastPage)
              _TapScale(
                onTap: (isValid && !isSubmitting) ? () => _goToPage(_currentPage + 1, state) : null,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isValid
                        ? (_currentPage == 0
                            ? AppColors.background
                            : AppColors.primaryDark)
                        : Colors.grey.shade400,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    color: _currentPage == 0 && isValid
                        ? AppColors.primaryDark
                        : AppColors.background,
                    size: 22,
                  ),
                ),
              ),
            if (isLastPage)
              _TapScale(
                key: const Key('finish_button'),
                onTap: (isValid && !isSubmitting)
                    ? () async {
                        final success = await ref
                            .read(onboardingSubmitProvider.notifier)
                            .submit(state);
                        if (success && mounted) {
                          await ref.read(sessionControllerProvider.notifier).refresh();
                        }
                      }
                    : null,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  decoration: BoxDecoration(
                    color: (isValid && !isSubmitting) ? AppColors.primaryDark : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Center(
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.background,
                            ),
                          )
                        : Text(
                            finishText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.background,
                              letterSpacing: -0.8,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({required String question, required Widget content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 20),
          content,
        ],
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    void Function(String)? onChanged,
    String? errorText,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    String? semanticsLabel,
  }) {
    return Semantics(
      label: semanticsLabel,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: onChanged,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.primaryDark,
          letterSpacing: -0.8,
        ),
        decoration: InputDecoration(
          hintText: hint,
          errorText: errorText,
          hintStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
            letterSpacing: -0.8,
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.primaryDark),
            borderRadius: BorderRadius.circular(12),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.primary),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppColors.primary),
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? initialValue,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String hint,
    String? errorText,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: initialValue,
      items: items,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.primaryDark,
        letterSpacing: -0.8,
      ),
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade500,
          letterSpacing: -0.8,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primaryDark),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppColors.primary),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
      dropdownColor: AppColors.background,
    );
  }

  Widget _buildYesNoOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 28),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.background : AppColors.primaryDark,
            letterSpacing: -0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildYesNo(OnboardingFormState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildYesNoOption(
              label: 'Yes',
              selected: state.hasUsedSimilarApps,
              onTap: () {
                ref.read(onboardingFormProvider.notifier).updateHasUsedSimilarApps(true);
              },
            ),
            const SizedBox(width: 12),
            _buildYesNoOption(
              label: 'No',
              selected: !state.hasUsedSimilarApps,
              onTap: () {
                ref.read(onboardingFormProvider.notifier).updateHasUsedSimilarApps(false);
                // clear experience
                ref.read(onboardingFormProvider.notifier).updateSimilarAppsExperience('');
                _experienceController.clear();
              },
            ),
          ],
        ),
        if (state.hasUsedSimilarApps) ...[
          const SizedBox(height: 14),
          _buildTextInput(
            controller: _experienceController,
            hint: 'Tell us about your experience...',
            maxLines: 3,
            maxLength: 500,
            onChanged: (val) => ref.read(onboardingFormProvider.notifier).updateSimilarAppsExperience(val),
            errorText: state.hasUsedSimilarApps && state.similarAppsExperience.isNotEmpty 
                ? state.validateSimilarAppsExperience() 
                : null,
            textInputAction: TextInputAction.done,
            semanticsLabel: 'Similar Apps Experience Input',
          ),
        ],
      ],
    );
  }

  Widget _buildIntroPage() {
    return const Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 40),
        child: Text(
          'Start your journey\nwith STARDY!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.background,
            letterSpacing: -0.8,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildPageAt(OnboardingPageType type, OnboardingFormState state) {
    switch (type) {
      case OnboardingPageType.intro:
        return _buildIntroPage();
      case OnboardingPageType.career:
        return _buildCard(
          question: 'What is your\ncareer goal?',
          content: _buildTextInput(
            controller: _goalController,
            hint: 'e.g. Full Stack Developer',
            maxLength: 100,
            onChanged: (val) => ref.read(onboardingFormProvider.notifier).updateCareerGoal(val),
            errorText: state.careerGoal.isNotEmpty ? state.validateCareerGoal() : null,
            textInputAction: TextInputAction.next,
            semanticsLabel: 'Career Goal Input',
          ),
        );
      case OnboardingPageType.purpose:
        return _buildCard(
          question: 'Define the Purpose for\nusing Stardy AI ?',
          content: _buildDropdown<OnboardingPurpose>(
            initialValue: state.purpose,
            items: OnboardingPurpose.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                .toList(),
            onChanged: (val) => ref.read(onboardingFormProvider.notifier).updatePurpose(val),
            hint: 'Select a purpose',
            errorText: state.validatePurpose(),
          ),
        );
      case OnboardingPageType.howHeard:
        return _buildCard(
          question: 'How did you hear\nabout us?',
          content: _buildDropdown<OnboardingHowHeard>(
            initialValue: state.howHeard,
            items: OnboardingHowHeard.values
                .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                .toList(),
            onChanged: (val) => ref.read(onboardingFormProvider.notifier).updateHowHeard(val),
            hint: 'Select an option',
            errorText: state.validateHowHeard(),
          ),
        );
      case OnboardingPageType.influencer:
        return _buildCard(
          question: 'Influencer details',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextInput(
                controller: _influencerNameController,
                hint: 'Influencer Name',
                maxLength: 80,
                onChanged: (val) => ref.read(onboardingFormProvider.notifier).updateInfluencerName(val),
                errorText: state.influencerName.isNotEmpty ? state.validateInfluencerName() : null,
                textInputAction: TextInputAction.next,
                semanticsLabel: 'Influencer Name Input',
              ),
              const SizedBox(height: 14),
              _buildTextInput(
                controller: _referralCodeController,
                hint: 'Referral Code (Optional)',
                maxLength: 32,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\-_]')),
                ],
                onChanged: (val) => ref.read(onboardingFormProvider.notifier).updateReferralCode(val),
                errorText: state.referralCodeUsed.isNotEmpty ? state.validateReferralCode() : null,
                textInputAction: TextInputAction.next,
                semanticsLabel: 'Referral Code Input',
              ),
            ],
          ),
        );
      case OnboardingPageType.expectation:
        return _buildCard(
          question: 'What do you expect\nto achieve?',
          content: _buildTextInput(
            controller: _achieveController,
            hint: 'Minimum 10 characters...',
            maxLines: 3,
            maxLength: 500,
            onChanged: (val) => ref.read(onboardingFormProvider.notifier).updateExpectation(val),
            errorText: state.expectation.isNotEmpty ? state.validateExpectation() : null,
            textInputAction: TextInputAction.next,
            semanticsLabel: 'Expectation Input',
          ),
        );
      case OnboardingPageType.similarApps:
        return _buildCard(
          question: 'Have you used\nsimilar apps before?',
          content: _buildYesNo(state),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingFormProvider);
    final pagesList = _getPagesList(state);

    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentPage == 0
                ? Container(
                    key: const ValueKey('dark-bg'),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFB51B39),
                          Color(0xFF1A0000),
                          Color(0xFF000000),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  )
                : Container(
                    key: const ValueKey('light-bg'),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.white, Color(0xff9A9A9A)],
                      ),
                    ),
                  ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/Group_17.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Stardy .AI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _currentPage == 0
                              ? AppColors.background
                              : AppColors.primary,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: pagesList.length,
                      onPageChanged: (i) {
                        setState(() {
                          _currentPage = i;
                        });
                      },
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double scale = 1.0;
                            double opacity = 1.0;
                            if (_pageController.position.haveDimensions) {
                              final page =
                                  _pageController.page ?? _currentPage.toDouble();
                              final distance = (page - index).abs().clamp(0.0, 1.0);
                              scale = 1.0 - (distance * 0.12);
                              opacity = 1.0 - (distance * 0.5);
                            }
                            return Center(
                              child: Opacity(
                                opacity: opacity,
                                child: Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: pagesList[index] == OnboardingPageType.intro
                                ? _buildPageAt(pagesList[index], state)
                                : SingleChildScrollView(
                                    child: _buildPageAt(pagesList[index], state),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildNavButtons(state),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────── TAP SCALE MICROINTERACTION ─────────────────
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TapScale({super.key, required this.child, this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap != null ? (_) => setState(() => _scale = 0.92) : null,
      onTapUp: widget.onTap != null ? (_) => setState(() => _scale = 1.0) : null,
      onTapCancel: widget.onTap != null ? () => setState(() => _scale = 1.0) : null,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
