import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/audio_event.dart';
import '../../data/models/recording_session.dart';
import '../../shared/widgets/luna_card.dart';
import '../tracking/tracking_screen.dart';
import 'providers/playback_provider.dart';

class RecordingDetailScreen extends ConsumerStatefulWidget {
  final RecordingSession session;
  final AudioEvent? event;

  const RecordingDetailScreen({
    super.key,
    required this.session,
    this.event,
  });

  @override
  ConsumerState<RecordingDetailScreen> createState() =>
      _RecordingDetailScreenState();
}

class _RecordingDetailScreenState
    extends ConsumerState<RecordingDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playbackProvider(widget.session).notifier).load();
    });
  }

  @override
  void dispose() {
    // Cleanup playback provider when leaving screen
    ref.invalidate(playbackProvider(widget.session));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackProvider(widget.session));
    final session = widget.session;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSessionInfo(context, session)
                          .animate()
                          .fadeIn(delay: 100.ms),
                      const SizedBox(height: 24),
                      _buildWaveformCard(context, session, playback)
                          .animate()
                          .fadeIn(delay: 200.ms),
                      const SizedBox(height: 24),
                      _buildPlayerControls(context, playback)
                          .animate()
                          .fadeIn(delay: 300.ms),
                      if (widget.event != null) ...[
                        const SizedBox(height: 24),
                        _buildEventDetail(context, widget.event!)
                            .animate()
                            .fadeIn(delay: 400.ms),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          Expanded(
            child: Text(
              'Recording Detail',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSessionInfo(
      BuildContext context, RecordingSession session) {
    return LunaCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.nights_stay_rounded,
                    color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.dateFull(session.startTime),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Formatters.timestamp(session.startTime)} → ${session.endTime != null ? Formatters.timestamp(session.endTime!) : 'In progress'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoPill(
                label: 'Duration',
                value: Formatters.durationLong(session.duration),
              ),
              _InfoPill(
                label: 'Snores',
                value: '${session.snoreCount}',
                valueColor: AppColors.snoreEvent,
              ),
              _InfoPill(
                label: 'Events',
                value: '${session.events.length}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformCard(BuildContext context, RecordingSession session,
      PlaybackState playback) {
    // Show full-session amplitude as waveform
    final amps = session.amplitudes;
    return LunaCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Full Night Waveform',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Tap to seek · highlights show detected events',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          GestureDetector(
            onTapDown: (details) {
              if (playback.duration.inMilliseconds == 0) return;
              final box = context.findRenderObject() as RenderBox;
              final localX = details.localPosition.dx;
              final width = box.size.width - 32; // padding
              final progress = (localX / width).clamp(0.0, 1.0);
              final seekPos = Duration(
                milliseconds:
                    (progress * playback.duration.inMilliseconds).toInt(),
              );
              ref
                  .read(playbackProvider(session).notifier)
                  .seek(seekPos);
            },
            child: SizedBox(
              height: 100,
              child: amps.isNotEmpty
                  ? LiveWaveformPainter(
                      amplitudes: _downsampleWaveform(amps, 150),
                      color: AppColors.secondary,
                    )
                  : const Center(
                      child: Text('No waveform data',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          LinearProgressIndicator(
            value: playback.progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 3,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(Formatters.duration(playback.position),
                  style: Theme.of(context).textTheme.labelSmall),
              Text(Formatters.duration(playback.duration),
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  List<double> _downsampleWaveform(List<double> data, int maxPoints) {
    if (data.length <= maxPoints) return data;
    final step = data.length / maxPoints;
    return List.generate(maxPoints, (i) => data[(i * step).floor()]);
  }

  Widget _buildPlayerControls(BuildContext context, PlaybackState playback) {
    final notifier = ref.read(playbackProvider(widget.session).notifier);
    final isPlaying = playback.status == PlaybackStatus.playing;
    final isLoading = playback.status == PlaybackStatus.loading;

    return LunaCard(
      showGlow: isPlaying,
      glowColor: AppColors.primary.withAlpha(40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Seek back 15s
          _ControlButton(
            icon: Icons.replay_10_rounded,
            onTap: () {
              final newPos = playback.position - const Duration(seconds: 10);
              notifier.seek(newPos < Duration.zero ? Duration.zero : newPos);
            },
          ),
          const SizedBox(width: 24),
          // Play / Pause
          GestureDetector(
            onTap: isLoading
                ? null
                : isPlaying
                    ? notifier.pause
                    : notifier.play,
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5)
                  : Icon(
                      isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
            ),
          ),
          const SizedBox(width: 24),
          // Seek forward 15s
          _ControlButton(
            icon: Icons.forward_10_rounded,
            onTap: () {
              final newPos = playback.position + const Duration(seconds: 10);
              final max = playback.duration;
              notifier.seek(newPos > max ? max : newPos);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetail(BuildContext context, AudioEvent event) {
    final color = _eventColor(event.type);
    return LunaCard(
      showGlow: true,
      glowColor: color.withAlpha(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(event.type.icon,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.type.label,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: color)),
                  Text(Formatters.dateTime(event.timestamp),
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _InfoPill(
                  label: 'Duration',
                  value:
                      '${(event.durationMs / 1000).toStringAsFixed(1)}s'),
              _InfoPill(
                  label: 'Peak Level',
                  value: '${(event.peakAmplitude * 100).toStringAsFixed(0)}%',
                  valueColor: color),
              _InfoPill(
                  label: 'Type',
                  value: event.type.name,
                  valueColor: color),
            ],
          ),
        ],
      ),
    );
  }

  Color _eventColor(AudioEventType type) {
    switch (type) {
      case AudioEventType.snore:
        return AppColors.snoreEvent;
      case AudioEventType.movement:
        return AppColors.movementEvent;
      case AudioEventType.environmentalNoise:
        return AppColors.envNoiseEvent;
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 22),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoPill({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textMuted)),
      ],
    );
  }
}
