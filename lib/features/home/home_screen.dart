import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/recording_session.dart';
import '../../features/tracking/providers/tracking_provider.dart';
import '../../shared/widgets/luna_button.dart';
import '../../shared/widgets/luna_card.dart';
import '../../shared/widgets/section_header.dart';
import '../results/results_screen.dart';
import '../tracking/tracking_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    _buildGreeting(context)
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 600.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 28),
                    _buildMainRing(context)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .scale(begin: const Offset(0.92, 0.92)),
                    const SizedBox(height: 24),
                    sessionsAsync.when(
                      data: (sessions) => _buildSessionStats(context, sessions),
                      loading: () => const _StatsSkeleton(),
                      error: (_, __) => const SizedBox.shrink(),
                    ).animate().fadeIn(delay: 350.ms, duration: 600.ms),
                    const SizedBox(height: 20),
                    _buildAmbientCard(context)
                        .animate()
                        .fadeIn(delay: 450.ms, duration: 600.ms)
                        .slideX(begin: 0.05, end: 0),
                    const SizedBox(height: 16),
                    _buildTipCard(context)
                        .animate()
                        .fadeIn(delay: 500.ms, duration: 600.ms)
                        .slideX(begin: -0.05, end: 0),
                    const SizedBox(height: 28),
                    _buildStartButton(context)
                        .animate()
                        .fadeIn(delay: 600.ms, duration: 600.ms)
                        .slideY(begin: 0.15, end: 0),
                    const SizedBox(height: 24),
                    sessionsAsync.when(
                      data: (sessions) => sessions.isNotEmpty
                          ? _buildRecentSessions(context, sessions)
                          : const SizedBox.shrink(),
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
        child: CircleAvatar(
          backgroundColor: AppColors.cardElevated,
          child: const Icon(Icons.person_rounded,
              color: AppColors.textSecondary, size: 20),
        ),
      ),
      title: Text(
        'LUNA',
        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              letterSpacing: 6,
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.nightlight_round,
                color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${Formatters.greeting()}, Alex',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ready for a restorative night?',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildMainRing(BuildContext context) {
    final sessions = ref.watch(sessionsProvider).valueOrNull ?? [];
    final hasSession = sessions.isNotEmpty && sessions.first.isComplete;
    final lastSession = hasSession ? sessions.first : null;
    final snoreCount = lastSession?.snoreCount ?? 0;
    final progress = hasSession
        ? math.max(0.0, 1.0 - (snoreCount / 20.0).clamp(0.0, 1.0))
        : 0.0;

    return Center(
      child: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow backdrop
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Container(
                width: 200 + _pulseController.value * 10,
                height: 200 + _pulseController.value * 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary
                          .withAlpha((30 + _pulseController.value * 20).toInt()),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
            // Arc ring
            CustomPaint(
              size: const Size(210, 210),
              painter: _RingPainter(progress: progress),
            ),
            // Center content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasSession) ...[
                  Text(
                    '${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    'SNORE SCORE',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 2,
                        ),
                  ),
                ] else ...[
                  const Icon(Icons.nightlight_round,
                      color: AppColors.primary, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'NO DATA YET',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          letterSpacing: 2,
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionStats(
      BuildContext context, List<RecordingSession> sessions) {
    final last = sessions.isNotEmpty ? sessions.first : null;
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'LAST NIGHT',
            value: last != null ? Formatters.durationLong(last.duration) : '—',
            icon: Icons.access_time_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(
            label: 'SNORE EVENTS',
            value: last != null ? '${last.snoreCount}' : '—',
            icon: Icons.graphic_eq_rounded,
            valueColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatChip(
            label: 'SESSIONS',
            value: '${sessions.length}',
            icon: Icons.nights_stay_rounded,
            valueColor: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildAmbientCard(BuildContext context) {
    return LunaCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.mic_rounded,
                color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ambient Noise',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('Ready to monitor',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text('— dB',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.secondary,
                  )),
        ],
      ),
    );
  }

  Widget _buildTipCard(BuildContext context) {
    return LunaCard(
      gradient: LinearGradient(
        colors: [
          AppColors.primaryDark.withAlpha(80),
          AppColors.card,
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sleep Tip',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Sleeping on your side reduces snoring frequency by up to 60%.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return LunaButton(
      label: 'Start Tracking',
      icon: Icons.play_arrow_rounded,
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TrackingScreen()),
      ),
    );
  }

  Widget _buildRecentSessions(
      BuildContext context, List<RecordingSession> sessions) {
    final recent = sessions.take(3).toList();
    return Column(
      children: [
        SectionHeader(
          title: 'Recent Sessions',
          trailing: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ResultsScreen(sessions: sessions)),
            ),
            child: Text('See All',
                style: TextStyle(color: AppColors.primary, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 12),
        ...recent.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SessionTile(session: s),
            )),
      ],
    );
  }
}

// ─── Ring painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 18) / 2;
    final strokeWidth = 9.0;

    // Background track
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.border;

    canvas.drawCircle(Offset(cx, cy), radius, trackPaint);

    // Gradient arc
    if (progress > 0) {
      final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius);
      final gradientPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.secondary],
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
        ).createShader(rect);

      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        gradientPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ─── Stat chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return LunaCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

// ─── Session tile ─────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final RecordingSession session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    return LunaCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ResultsScreen(sessions: [session], initialIndex: 0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.nights_stay_rounded,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.dateFull(session.startTime),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.durationLong(session.duration)} · ${session.snoreCount} snore events',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

// ─── Skeletons ────────────────────────────────────────────────────────────────

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: i < 2 ? 12 : 0),
          child: LunaCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: const SizedBox(height: 60),
          ),
        ),
      )),
    );
  }
}
