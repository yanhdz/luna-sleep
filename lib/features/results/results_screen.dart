import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/audio_event.dart';
import '../../data/models/recording_session.dart';
import '../../features/tracking/providers/tracking_provider.dart';
import '../../shared/widgets/luna_button.dart';
import '../../shared/widgets/luna_card.dart';
import '../../shared/widgets/section_header.dart';
import '../recording_detail/recording_detail_screen.dart';
import '../recording_detail/providers/playback_provider.dart';

class ResultsScreen extends ConsumerStatefulWidget {
  final List<RecordingSession> sessions;
  final int initialIndex;

  const ResultsScreen({
    super.key,
    required this.sessions,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends ConsumerState<ResultsScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _tabController = TabController(
      length: widget.sessions.length.clamp(1, widget.sessions.length),
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  RecordingSession get _session => widget.sessions[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              if (widget.sessions.length > 1) _buildSessionTabs(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildSessionHeader(context)
                          .animate()
                          .fadeIn(delay: 100.ms),
                      const SizedBox(height: 20),
                      _buildStatCards(context)
                          .animate()
                          .fadeIn(delay: 200.ms),
                      const SizedBox(height: 24),
                      _buildNoiseTimeline(context)
                          .animate()
                          .fadeIn(delay: 300.ms),
                      const SizedBox(height: 24),
                      _buildAudioPlayback(context)
                          .animate()
                          .fadeIn(delay: 350.ms),
                      const SizedBox(height: 24),
                      _buildEventsList(context)
                          .animate()
                          .fadeIn(delay: 400.ms),
                      const SizedBox(height: 24),
                      _buildActions(context)
                          .animate()
                          .fadeIn(delay: 500.ms),
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
              'SNORE ANALYSIS',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 3,
                    color: AppColors.textSecondary,
                  ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildSessionTabs() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: widget.sessions.length,
        itemBuilder: (context, i) {
          final s = widget.sessions[i];
          final selected = i == _selectedIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Text(
                Formatters.dateShort(s.startTime),
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Formatters.dateFull(_session.startTime),
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '${Formatters.timestamp(_session.startTime)} → ${_session.endTime != null ? Formatters.timestamp(_session.endTime!) : 'In progress'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        _snoreFrequencyBadge(context),
      ],
    );
  }

  Widget _snoreFrequencyBadge(BuildContext context) {
    final dur = _session.duration.inMinutes;
    final freq = dur > 0
        ? (_session.snoreCount / (dur / 60)).toStringAsFixed(0)
        : '0';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$freq%',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
        ),
        Text('Avg Frequency',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildStatCards(BuildContext context) {
    final s = _session;
    return Row(
      children: [
        Expanded(
          child: _ResultStat(
            label: 'DURATION',
            value: Formatters.durationLong(s.duration),
            icon: Icons.access_time_rounded,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ResultStat(
            label: 'SNORE EVENTS',
            value: '${s.snoreCount}',
            icon: Icons.graphic_eq_rounded,
            color: AppColors.snoreEvent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ResultStat(
            label: 'NOISY TIME',
            value: '${s.noisyPercent.toStringAsFixed(0)}%',
            icon: Icons.bar_chart_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ResultStat(
            label: 'PEAKS',
            value: '${s.peakCount}',
            icon: Icons.show_chart_rounded,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildNoiseTimeline(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Noise Timeline'),
        const SizedBox(height: 14),
        LunaCard(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: _session.amplitudes.isNotEmpty
              ? _NoiseLineChart(amplitudes: _session.amplitudes)
              : const _EmptyChart(),
        ),
      ],
    );
  }

  Widget _buildAudioPlayback(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Audio Playback'),
        const SizedBox(height: 14),
        LunaCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _AudioPlayerWidget(session: _session),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList(BuildContext context) {
    final events = _session.events;
    return Column(
      children: [
        SectionHeader(
          title: 'Detected Events',
          subtitle: '${events.length} total',
          trailing: events.isNotEmpty
              ? Text(
                  'CLEAR ALL',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1),
                )
              : null,
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          LunaCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.secondary, size: 36),
                    const SizedBox(height: 10),
                    Text('No events detected',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: AppColors.secondary)),
                    Text('Quiet night!',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          )
        else
          ...events.take(20).map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EventTile(
                  event: e,
                  session: _session,
                ),
              )),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        LunaButton(
          label: 'New Recording',
          icon: Icons.add_rounded,
          onPressed: () {
            ref.read(trackingProvider.notifier).resetToIdle();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          gradient: AppColors.cyanGradient,
        ),
        const SizedBox(height: 12),
        LunaButton(
          label: 'Delete This Session',
          icon: Icons.delete_outline_rounded,
          isDestructive: true,
          onPressed: () => _confirmDelete(context),
          backgroundColor: AppColors.card,
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final notifier = ref.read(sessionsProvider.notifier);
    final sessionId = _session.id;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardElevated,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Session?'),
        content:
            const Text('This will permanently delete the recording and all data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await notifier.delete(sessionId);
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }
}

// ─── Noise line chart ─────────────────────────────────────────────────────────

class _NoiseLineChart extends StatelessWidget {
  final List<double> amplitudes;
  const _NoiseLineChart({required this.amplitudes});

  @override
  Widget build(BuildContext context) {
    // Downsample to max 200 points for performance
    final data = _downsample(amplitudes, 200);
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i]));
    }

    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 0.25,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 0.5,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(
                  v == 0 ? 'Low' : v == 1 ? 'High' : '',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: 1,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: AppColors.secondary,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withAlpha(60),
                    AppColors.secondary.withAlpha(0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.cardElevated,
              tooltipRoundedRadius: 8,
              getTooltipItems: (spots) => spots.map((s) {
                return LineTooltipItem(
                  '${(s.y * 60).toStringAsFixed(0)} dB',
                  const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
        ),
        duration: const Duration(milliseconds: 0),
      ),
    );
  }

  List<double> _downsample(List<double> data, int maxPoints) {
    if (data.length <= maxPoints) return data;
    final step = data.length / maxPoints;
    return List.generate(maxPoints, (i) => data[(i * step).floor()]);
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Text('No amplitude data recorded',
            style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

// ─── Event tile ───────────────────────────────────────────────────────────────

class _EventTile extends ConsumerWidget {
  final AudioEvent event;
  final RecordingSession session;
  const _EventTile({required this.event, required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _eventColor(event.type);
    return LunaCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecordingDetailScreen(
            session: session,
            event: event,
          ),
        ),
      ),
      child: Row(
        children: [
          // Play button
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withAlpha(80)),
            ),
            child:
                Icon(Icons.play_arrow_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.type.label,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${Formatters.timestamp(event.timestamp)} · ${(event.durationMs / 1000).toStringAsFixed(0)} seconds',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Mini waveform preview
          _MiniWaveform(color: color),
          const SizedBox(width: 10),
          Icon(Icons.delete_outline_rounded,
              color: AppColors.textMuted, size: 18),
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

class _MiniWaveform extends StatelessWidget {
  final Color color;
  const _MiniWaveform({required this.color});

  @override
  Widget build(BuildContext context) {
    const heights = [0.4, 0.7, 0.5, 0.9, 0.6, 0.8, 0.4, 0.6, 0.3];
    return Row(
      children: heights.map((h) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: Container(
            width: 3,
            height: 24 * h,
            decoration: BoxDecoration(
              color: color.withAlpha(160),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Stat card ────────────────────────────────────────────────────────────────

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ResultStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LunaCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  )),
          const SizedBox(height: 2),
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 9,
                    letterSpacing: 1,
                  )),
        ],
      ),
    );
  }
}

class _AudioPlayerWidget extends ConsumerStatefulWidget {
  final RecordingSession session;
  const _AudioPlayerWidget({required this.session});

  @override
  ConsumerState<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<_AudioPlayerWidget> {
  @override
  void initState() {
    super.initState();
    // Load audio when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playbackProvider(widget.session).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playbackProvider(widget.session));
    final notifier = ref.read(playbackProvider(widget.session).notifier);
    final isPlaying = playback.status == PlaybackStatus.playing;
    final isLoading = playback.status == PlaybackStatus.loading;
    final isError = playback.status == PlaybackStatus.error;

    return Column(
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: playback.progress.clamp(0.0, 1.0),
            backgroundColor: AppColors.border,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 10),
        // Time display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(Formatters.duration(playback.position),
                style: Theme.of(context).textTheme.labelSmall),
            Text(Formatters.duration(playback.duration),
                style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 16),
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rewind 15s
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () {
                      final newPos =
                          playback.position - const Duration(seconds: 15);
                      notifier.seek(newPos < Duration.zero
                          ? Duration.zero
                          : newPos);
                    },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fast_rewind,
                    color: AppColors.primary, size: 20),
              ),
            ),
            const SizedBox(width: 20),
            // Play / Pause
            GestureDetector(
              onTap: isLoading
                  ? null
                  : isError
                      ? null
                      : isPlaying
                          ? notifier.pause
                          : notifier.play,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isError
                      ? LinearGradient(
                          colors: [
                            AppColors.textMuted.withAlpha(80),
                            AppColors.textMuted.withAlpha(80)
                          ],
                        )
                      : AppColors.primaryGradient,
                  boxShadow: isError
                      ? []
                      : [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(80),
                            blurRadius: 16,
                            spreadRadius: 0,
                          ),
                        ],
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5)
                    : isError
                        ? const Icon(Icons.error_outline,
                            color: Colors.white, size: 28)
                        : Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
              ),
            ),
            const SizedBox(width: 20),
            // Forward 15s
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () {
                      final newPos =
                          playback.position + const Duration(seconds: 15);
                      notifier.seek(newPos > playback.duration
                          ? playback.duration
                          : newPos);
                    },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fast_forward,
                    color: AppColors.primary, size: 20),
              ),
            ),
          ],
        ),
        if (isError && playback.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              playback.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.snoreEvent,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}
