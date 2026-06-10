import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/luna_button.dart';
import '../../shared/widgets/luna_card.dart';
import '../results/results_screen.dart';
import 'providers/tracking_provider.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late final ProviderSubscription<TrackingState> _trackingSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _trackingSubscription = ref.listenManual<TrackingState>(
      trackingProvider,
      (prev, next) async {
        if (next.status != TrackingStatus.done || next.currentSession == null) {
          return;
        }

        final finishedSession = next.currentSession!;
        ref.read(sessionsProvider.notifier).reload();
        await ref.read(trackingProvider.notifier).resetToIdle();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResultsScreen(
              sessions: [finishedSession],
              initialIndex: 0,
            ),
          ),
        );
      },
    );

    if (ref.read(trackingProvider).status == TrackingStatus.done) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(trackingProvider.notifier).resetToIdle();
      });
    }
  }

  @override
  void dispose() {
    _trackingSubscription.close();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(trackingProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, state),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildBody(context, state),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, TrackingState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          if (state.status == TrackingStatus.idle ||
              state.status == TrackingStatus.requestingPermission)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
            )
          else
            const SizedBox(width: 48),
          Expanded(
            child: Text('LUNA',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      letterSpacing: 6,
                      color: AppColors.primary,
                    )),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, TrackingState state) {
    switch (state.status) {
      case TrackingStatus.idle:
      case TrackingStatus.requestingPermission:
        return _buildIdleView(context, state);
      case TrackingStatus.recording:
        return _buildRecordingView(context, state);
      case TrackingStatus.processing:
        return _buildProcessingView(context);
      case TrackingStatus.done:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIdleView(BuildContext context, TrackingState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Big pulsing mic icon
        AnimatedBuilder(
          animation: _pulseController,
          builder: (_, __) => Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary
                      .withAlpha((20 + _pulseController.value * 40).toInt()),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.mic_none_rounded,
                size: 60, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 32),
        Text('Ready to Monitor',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(
          'LUNA will record audio overnight and\ndetect snoring events automatically.',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(height: 1.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        _buildInfoChips(context),
        const SizedBox(height: 40),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: LunaCard(
              color: AppColors.danger.withAlpha(20),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.danger, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(state.errorMessage!,
                        style: TextStyle(
                            color: AppColors.danger, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        LunaButton(
          label: state.status == TrackingStatus.requestingPermission
              ? 'Requesting Permission...'
              : 'Start Tracking',
          icon: Icons.play_arrow_rounded,
          isLoading:
              state.status == TrackingStatus.requestingPermission,
          onPressed: () =>
              ref.read(trackingProvider.notifier).startTracking(),
        ),
        const SizedBox(height: 12),
        Text(
          'Keep the app open for best results',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildInfoChips(BuildContext context) {
    const items = [
      ('Up to 8h', Icons.schedule_rounded),
      ('Offline', Icons.wifi_off_rounded),
      ('No cloud', Icons.cloud_off_rounded),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$2, size: 13, color: AppColors.secondary),
                const SizedBox(width: 5),
                Text(item.$1,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecordingView(BuildContext context, TrackingState state) {
    final dbValue = state.currentDecibels.toStringAsFixed(0);
    return Column(
      children: [
        const SizedBox(height: 24),
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.danger.withAlpha(20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.danger.withAlpha(80)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.danger.withAlpha(
                        (150 + _pulseController.value * 105).toInt()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('RECORDING',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5)),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
        const SizedBox(height: 32),
        // Timer
        Text(
          Formatters.duration(state.elapsed),
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w300,
                letterSpacing: 4,
              ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(
              duration: 4000.ms,
              color: AppColors.primary.withAlpha(80),
            ),
        const SizedBox(height: 6),
        Text('elapsed time',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(letterSpacing: 1.5)),
        const SizedBox(height: 32),
        // Live waveform
        LunaCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.graphic_eq_rounded,
                      color: AppColors.secondary, size: 16),
                  const SizedBox(width: 8),
                  Text('LIVE AUDIO',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.secondary,
                            letterSpacing: 2,
                          )),
                  const Spacer(),
                  Text('$dbValue dB',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 80,
                child: LiveWaveformPainter(
                  amplitudes: state.recentAmplitudes,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // dB meter row
        Row(
          children: [
            Expanded(
              child: _DbMeterCard(
                label: 'CURRENT',
                value: state.currentAmplitude,
                decibels: state.currentDecibels,
                color: _dbColor(state.currentAmplitude),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _EventCountCard(
                snores: state.currentSession != null ? 0 : 0,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Stop button
        LunaButton(
          label: 'Stop Recording',
          icon: Icons.stop_rounded,
          isDestructive: true,
          onPressed: () =>
              ref.read(trackingProvider.notifier).stopTracking(),
        ),
        const SizedBox(height: 12),
        Text(
          'Keep the phone nearby and plugged in',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProcessingView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 24),
        Text('Analyzing recording…',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Text('Detecting snore events',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    ).animate().fadeIn();
  }

  Color _dbColor(double normalized) {
    if (normalized >= 0.75) return AppColors.danger;
    if (normalized >= 0.5) return AppColors.warning;
    return AppColors.secondary;
  }
}

// ─── Live Waveform Widget ─────────────────────────────────────────────────────

class LiveWaveformPainter extends StatelessWidget {
  final List<double> amplitudes;
  final Color color;

  const LiveWaveformPainter({
    super.key,
    required this.amplitudes,
    this.color = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformCustomPainter(
          amplitudes: amplitudes, color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _WaveformCustomPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  _WaveformCustomPainter({required this.amplitudes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) {
      _drawFlatLine(canvas, size);
      return;
    }

    final barWidth = 3.0;
    final gap = 2.0;
    final totalBars = (size.width / (barWidth + gap)).floor();
    final data = amplitudes.length > totalBars
        ? amplitudes.sublist(amplitudes.length - totalBars)
        : amplitudes;

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < data.length; i++) {
      final x = i * (barWidth + gap);
      final normalizedHeight = math.max(0.06, data[i]);
      final barHeight = normalizedHeight * size.height;
      final top = (size.height - barHeight) / 2;

      // Gradient color: dim for older, bright for recent
      final fade = (i / data.length);
      paint.color = color.withAlpha((80 + (fade * 175).toInt()));

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, barHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  void _drawFlatLine(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(60)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_WaveformCustomPainter old) =>
      old.amplitudes != amplitudes;
}

// ─── dB Meter Card ────────────────────────────────────────────────────────────

class _DbMeterCard extends StatelessWidget {
  final String label;
  final double value; // 0..1
  final double decibels;
  final Color color;

  const _DbMeterCard({
    required this.label,
    required this.value,
    required this.decibels,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LunaCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    color: AppColors.textMuted,
                  )),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${decibels.toStringAsFixed(0)} dB',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _EventCountCard extends StatelessWidget {
  final int snores;
  const _EventCountCard({required this.snores});

  @override
  Widget build(BuildContext context) {
    return LunaCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SNORE EVENTS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.5,
                    color: AppColors.textMuted,
                  )),
          const SizedBox(height: 10),
          Text(
            '$snores',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          Text('detected so far',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
