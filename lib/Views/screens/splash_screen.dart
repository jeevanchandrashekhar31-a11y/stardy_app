import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/color_codes.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/session/session_controller.dart';
import '../../Routers/routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _riseController;
  late AnimationController _shrinkController;
  late AnimationController _logoController;
  late AnimationController _fadeTextController;

  late Animation<double> _riseAnimation;
  late Animation<double> _shrinkAnimation;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeTextAnimation;

  bool _animationStarted = false;

  Timer? _autoTransitionTimer;

  @override
  void initState() {
    super.initState();

    _fadeTextController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _shrinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeTextAnimation = CurvedAnimation(
      parent: _fadeTextController,
      curve: Curves.easeOut,
    );

    _riseAnimation = CurvedAnimation(
      parent: _riseController,
      curve: Curves.easeInOut,
    );

    _shrinkAnimation = CurvedAnimation(
      parent: _shrinkController,
      curve: Curves.easeInOut,
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );

    // Sensible minimum display time: 2.0s
    _autoTransitionTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        final sessionState = ref.read(sessionControllerProvider);
        if (sessionState is SessionReady || sessionState is SessionNeedsOnboarding) {
          _handleSwipeUp();
        }
      }
    });
  }

  void _handleSwipeUp() async {
    if (_animationStarted) return;
    setState(() => _animationStarted = true);
    _autoTransitionTimer?.cancel();

    // Step 1: Fade out text
    await _fadeTextController.forward();

    // Step 2: Big circle rises from bottom
    await _riseController.forward();

    // Step 3: Circle shrinks to center
    await _shrinkController.forward();

    // Step 4: Logo fades in
    await _logoController.forward();

    // Step 5: Navigate
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      ref.read(splashFinishedProvider.notifier).state = true;
    }
  }

  @override
  void dispose() {
    _autoTransitionTimer?.cancel();
    _fadeTextController.dispose();
    _riseController.dispose();
    _shrinkController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bigSize = size.width * 1.6;
    final smallSize = size.width * 0.1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! < -100) {
            _handleSwipeUp();
          }
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _fadeTextAnimation,
            _riseAnimation,
            _shrinkAnimation,
            _logoAnimation,
          ]),
          builder: (context, child) {
            // Circle size calculation
            final currentSize = _shrinkAnimation.value > 0
                ? bigSize - ((bigSize - smallSize) * _shrinkAnimation.value)
                : bigSize * _riseAnimation.value + (size.width * 0.3);

            // Circle vertical position
            double circleTop;
            if (_shrinkAnimation.value > 0) {
              // Moving to center while shrinking
              final centerPos = size.height / 2 - currentSize / 2;
              circleTop = centerPos * _shrinkAnimation.value;
            } else {
              // Rising from bottom
              circleTop = size.height - (currentSize * _riseAnimation.value);
            }

            return Stack(
              children: [
                //.background background
                Container(color: AppColors.background),

                // Text — fades out on swipe
                Opacity(
                  opacity: (1 - _fadeTextAnimation.value).clamp(0.0, 1.0),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(
                      child: Text(
                        'Get Skilled Get\nStardy AI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.8,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ),

                // Swipe up text — fades out on swipe
                Opacity(
                  opacity: (1 - _fadeTextAnimation.value).clamp(0.0, 1.0),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 50),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.grey,
                            size: 20,
                          ),
                          Text(
                            'Swipe Up to Enter',
                            style: TextStyle(
                              fontSize: 12,
                              letterSpacing: -0.8,
                              color: AppColors.primaryDark.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Static arc at bottom before swipe
                if (!_animationStarted)
                  Positioned(
                    bottom: -size.width * 0.55,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: size.width * 0.8,
                        height: size.width * 0.8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.withValues(alpha: 0.12),
                        ),
                      ),
                    ),
                  ),

                // Animated circle — rises then shrinks to center
                if (_riseAnimation.value > 0 && _logoAnimation.value == 0)
                  Positioned(
                    top: circleTop,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: currentSize,
                        height: currentSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                  ),

                // Logo + small glow circle in center
                if (_logoAnimation.value > 0)
                  Opacity(
                    opacity: _logoAnimation.value,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Small glow circle behind logo
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: smallSize,
                                height: smallSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.withValues(alpha: 0.12),
                                ),
                              ),
                              Container(
                                width: 90,
                                height: 90,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryDark,
                                  shape: BoxShape.circle,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/Group_17.png',
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Stardy .AI',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.8,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
