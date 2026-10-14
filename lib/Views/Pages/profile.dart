import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/feature_flags.dart';
import '../../core/url/safe_launcher.dart';
import '../CareerPath/career_path_detail_page.dart';
import '../widgets/color_codes.dart';
import 'settings_page.dart';
import '../../features/profile/repository/profile_repository.dart';
import '../../features/gamification/repository/gamification_repository.dart';
import '../../features/gamification/dto/gamification_badge_dto.dart';
import '../../features/gamification/dto/certificate_dto.dart';
import '../../features/profile/dto/user_profile_dto.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {

  @override
  Widget build(BuildContext context) {
    final meAsync = ref.watch(meProvider);
    final gamificationAsync = ref.watch(gamificationProvider);

    if (meAsync.isLoading || gamificationAsync.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (meAsync.hasError || gamificationAsync.hasError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load profile.', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(meProvider);
                  ref.invalidate(gamificationProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final me = meAsync.value!;
    final gamification = gamificationAsync.value!;
    final xpProgress = gamification.xpForNextLevel > 0 
        ? (gamification.xpIntoLevel / gamification.xpForNextLevel).toDouble() 
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(meProvider);
          ref.invalidate(gamificationProvider);
          try {
            await ref.read(meProvider.future);
            await ref.read(gamificationProvider.future);
          } catch (_) {}
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, me.username ?? me.name),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _StreakAndBadgesCarousel(
                        streak: gamification.currentStreak, 
                        name: me.name,
                      ),
                      const SizedBox(height: 20),
                      _buildXpSection(gamification.xp, gamification.level, xpProgress),
                      const SizedBox(height: 28),
                      _buildWeekRewind(),
                      _buildCareerInterests(context, me.careerPaths),
                      _buildLoginWith(context),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── HEADER ─────────────────
  Widget _buildHeader(BuildContext context, String username) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      decoration: const BoxDecoration(
        color: AppColors.primaryDark,
        image: DecorationImage(
          image: AssetImage('assets/images/profile_banner.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TapScale(
                onTap: () => Navigator.maybePop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chevron_left, color: Colors.black),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.ios_share, color: Colors.white70, size: 22),
                  const SizedBox(width: 16),
                  _TapScale(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
              border: Border.all(color: Colors.white24, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/profile_avatar.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            username,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── XP SECTION ─────────────────
  Widget _buildXpSection(int xp, int level, double xpProgress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$xp ',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text: 'XP',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'LEVEL ',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: '$level',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: xpProgress),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 10,
              backgroundColor: Colors.black12,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────── WEEK REWIND ─────────────────
  Widget _buildWeekRewind() {
    if (!FeatureFlags.weekRewind) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Features doc section 4.1 (deferred)
        const Text(
          'Week Rewind',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                height: 130,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Strongest Subject',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Design Thinking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Text(
                      'Subject you need to work on',
                      style: TextStyle(color: Colors.white54, fontSize: 11),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Empathy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                height: 130,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hours studied',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '30 Hours',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weeks Enrolled',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '6 Weeks',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                          .map(
                            (d) => Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 1,
                                ),
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    d,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ───────────────── CAREER INTERESTS ─────────────────
  Widget _buildCareerInterests(BuildContext context, List<CareerPathProgressDto> careerPaths) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Career Interests',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...careerPaths.map(
              (path) => _TapScale(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CareerPathDetailPage(
                        pathId: path.id,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryDark,
                        AppColors.primary.withValues(alpha: 0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    path.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            _TapScale(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add a career interest'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  // ───────────────── LOGIN WITH ─────────────────
  Widget _buildLoginWith(BuildContext context) {
    if (!FeatureFlags.socialLinks) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Features doc section 4.1 (deferred)
        const Text(
          'Log In with',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _socialIcon(
              context,
              label: 'Instagram',
              child: const Icon(
                Icons.camera_alt_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            _socialIcon(
              context,
              label: 'Discord',
              child: const _DiscordGlyph(color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            _socialIcon(
              context,
              label: 'X',
              child: const Icon(Icons.close, color: AppColors.primary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _socialIcon(
    BuildContext context, {
    required String label,
    required Widget child,
  }) {
    return _TapScale(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label sign-in isn\'t available in this demo yet'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ───────────────── TAP SCALE MICROINTERACTION ─────────────────
class _TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _TapScale({required this.child, this.onTap});

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _scale = 0.9),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ───────────────── DISCORD-STYLE GLYPH ─────────────────
class _DiscordGlyph extends StatelessWidget {
  final Color color;
  final double size;

  const _DiscordGlyph({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DiscordGlyphPainter(color),
    );
  }
}

class _DiscordGlyphPainter extends CustomPainter {
  final Color color;
  _DiscordGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;

    final body = RRect.fromRectAndCorners(
      Rect.fromLTWH(w * 0.05, h * 0.15, w * 0.9, h * 0.65),
      topLeft: Radius.circular(w * 0.35),
      topRight: Radius.circular(w * 0.35),
      bottomLeft: Radius.circular(w * 0.45),
      bottomRight: Radius.circular(w * 0.45),
    );
    canvas.drawRRect(body, paint);

    canvas.drawCircle(Offset(w * 0.18, h * 0.24), w * 0.12, paint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.24), w * 0.12, paint);

    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.36, h * 0.48), w * 0.07, eyePaint);
    canvas.drawCircle(Offset(w * 0.64, h * 0.48), w * 0.07, eyePaint);
  }

  @override
  bool shouldRepaint(covariant _DiscordGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ───────────────── STREAK + BADGES CAROUSEL ─────────────────
class _StreakAndBadgesCarousel extends StatefulWidget {
  final int streak;
  final String name;
  const _StreakAndBadgesCarousel({required this.streak, required this.name});

  @override
  State<_StreakAndBadgesCarousel> createState() =>
      _StreakAndBadgesCarouselState();
}

class _StreakAndBadgesCarouselState extends State<_StreakAndBadgesCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 430,
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            children: [
              _StreakCard(streak: widget.streak, name: widget.name),
              const _BadgesCard(),
              const _CertificationsCard(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final isActive = _page == i;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: isActive ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ───────────────── STREAK CARD ─────────────────
class _StreakCard extends StatefulWidget {
  final int streak;
  final String name;
  const _StreakCard({required this.streak, required this.name});

  @override
  State<_StreakCard> createState() => _StreakCardState();
}

class _StreakCardState extends State<_StreakCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flameController;

  @override
  void initState() {
    super.initState();
    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const checked = [true, true, true, true, false, false, false];
    const dates = [null, null, null, null, '29', '30', '31'];
    const todayIndex = 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '${widget.streak}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'Days Streak',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "You're doing really great ${widget.name}",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Container(
            width: 74,
            height: 74,
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: AnimatedBuilder(
              animation: _flameController,
              builder: (context, child) {
                final t = _flameController.value;
                final scale = 1.0 + (t * 0.14);
                final angle = (t - 0.5) * 0.14;
                return Transform.rotate(
                  angle: angle,
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: Image.asset('assets/images/icon_streak_flame.png'),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(days.length, (i) {
              final isToday = i == todayIndex;
              return Column(
                children: [
                  Text(
                    days[i],
                    style: TextStyle(
                      color: isToday ? Colors.white : Colors.white38,
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: checked[i]
                          ? AppColors.primary
                          : (isToday ? Colors.white : Colors.transparent),
                    ),
                    child: Center(
                      child: checked[i]
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 16,
                            )
                          : Text(
                              dates[i] ?? '',
                              style: TextStyle(
                                color: isToday ? Colors.black : Colors.white38,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ───────────────── BADGES CARD ─────────────────
class _BadgesCard extends ConsumerWidget {
  const _BadgesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgesAsync = ref.watch(badgesProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR BADGES',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: badgesAsync.when(
              data: (allBadges) {
                final earned = allBadges.where((b) => b.earned).toList();
                if (earned.isEmpty) {
                  return const Center(
                    child: Text(
                      'No badges yet',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  );
                }
                return GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  physics: const NeverScrollableScrollPhysics(),
                  children: earned.map(_buildBadgeTile).toList(),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              error: (err, stack) => const Center(
                child: Text('Failed to load badges', style: TextStyle(color: Colors.white54)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeTile(GamificationBadgeDto badge) {
    return _TapScale(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.hexagon, color: AppColors.primary, size: 56),
                _buildBadgeIcon(badge),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              badge.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeIcon(GamificationBadgeDto badge) {
    if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: badge.iconUrl!,
        width: 26,
        height: 26,
        memCacheWidth: 52,
        memCacheHeight: 52,
        placeholder: (context, url) => const SizedBox(width: 26, height: 26),
        errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white, size: 22),
      );
    }
    IconData icon;
    switch (badge.code) {
      case 'EARLY_BIRD':
        icon = Icons.flutter_dash;
        break;
      case 'FIRST_LAUNCH':
        icon = Icons.rocket_launch;
        break;
      case 'MULTITASKER':
        icon = Icons.castle;
        break;
      case 'COMEBACK_KID':
        icon = Icons.shield;
        break;
      default:
        icon = Icons.military_tech;
        break;
    }
    return Icon(icon, color: Colors.white, size: 22);
  }
}

// ───────────────── CERTIFICATIONS CARD ─────────────────
class _CertificationsCard extends ConsumerWidget {
  const _CertificationsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certsState = ref.watch(certificatesProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CERTIFICATIONS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: certsState.isLoading && certsState.items.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : certsState.error != null && certsState.items.isEmpty
                    ? const Center(
                        child: Text('Failed to load certifications',
                            style: TextStyle(color: Colors.white54)),
                      )
                    : certsState.items.isEmpty
                        ? const Center(
                            child: Text(
                              'No certifications yet',
                              style: TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          )
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: certsState.items.length +
                                (certsState.hasMore ? 1 : 0),
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              if (i == certsState.items.length) {
                                return Center(
                                  child: TextButton(
                                    onPressed: () {
                                      ref
                                          .read(certificatesProvider.notifier)
                                          .loadMore();
                                    },
                                    child: certsState.isLoading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Text('Load more',
                                            style:
                                                TextStyle(color: Colors.white70)),
                                  ),
                                );
                              }
                              return _buildCertTile(context, certsState.items[i]);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertTile(BuildContext context, CertificateDto cert) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[cert.issuedAt.month - 1]} ${cert.issuedAt.year}';

    return _TapScale(
      onTap: () {
        SafeLauncher.launchSafe(context, cert.certificateUrl);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.workspace_premium, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cert.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${cert.courseTitle} · $dateStr',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
