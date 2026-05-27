import '../../data/models/audio_event.dart';
import '../constants/app_constants.dart';

class AmplitudeProcessor {
  AmplitudeProcessor._();

  /// Normalize a raw dBFS value (typically -160..0) to 0.0..1.0
  static double normalize(double dbFs) {
    // dBFS: 0 is max, -160 is silence. Map to 0..1.
    const silence = -60.0; // treat anything below -60 as silence
    if (dbFs >= 0) return 1.0;
    if (dbFs <= silence) return 0.0;
    return (dbFs - silence) / (0 - silence);
  }

  /// Average amplitude (normalized 0..1)
  static double average(List<double> amplitudes) {
    if (amplitudes.isEmpty) return 0.0;
    return amplitudes.reduce((a, b) => a + b) / amplitudes.length;
  }

  /// Percentage of samples above a normalized threshold
  static double noisyPercent(List<double> amplitudes, {double threshold = 0.4}) {
    if (amplitudes.isEmpty) return 0.0;
    final loud = amplitudes.where((a) => a >= threshold).length;
    return (loud / amplitudes.length) * 100.0;
  }

  /// Count local peaks above threshold
  static int countPeaks(List<double> amplitudes, {double threshold = 0.6}) {
    int peaks = 0;
    bool wasAbove = false;
    for (final a in amplitudes) {
      if (a >= threshold && !wasAbove) {
        peaks++;
        wasAbove = true;
      } else if (a < threshold) {
        wasAbove = false;
      }
    }
    return peaks;
  }

  /// Detect audio events from a time-series of normalized amplitudes.
  /// [startTime] is the recording start; amplitudes are sampled every
  /// [AppConstants.amplitudeSampleRateMs] ms.
  static List<AudioEvent> detectEvents(
    List<double> amplitudes,
    DateTime startTime,
  ) {
    final events = <AudioEvent>[];
    final sampleMs = AppConstants.amplitudeSampleRateMs;
    final minSamples = AppConstants.minSnoreDurationMs ~/ sampleMs;
    final gapSamples = AppConstants.minEventGapMs ~/ sampleMs;

    int consecutiveHigh = 0;
    int? eventStartIndex;
    int lastEventEndIndex = -gapSamples;

    for (int i = 0; i < amplitudes.length; i++) {
      final a = amplitudes[i];

      if (a >= 0.5) {
        consecutiveHigh++;
        eventStartIndex ??= i;
      } else {
        if (consecutiveHigh >= minSamples &&
            (eventStartIndex! - lastEventEndIndex) >= gapSamples) {
          final offsetMs = eventStartIndex * sampleMs;
          final durationMs = consecutiveHigh * sampleMs;
          final peak = _peakInRange(amplitudes, eventStartIndex, i);

          events.add(AudioEvent(
            id: '${startTime.millisecondsSinceEpoch}_$eventStartIndex',
            timestamp: startTime.add(Duration(milliseconds: offsetMs)),
            type: _classifyEvent(peak, durationMs),
            durationMs: durationMs,
            peakAmplitude: peak,
            amplitudeStartIndex: eventStartIndex,
            amplitudeLength: consecutiveHigh,
          ));
          lastEventEndIndex = i;
        }
        consecutiveHigh = 0;
        eventStartIndex = null;
      }
    }

    return events;
  }

  static double _peakInRange(List<double> amps, int start, int end) {
    double peak = 0;
    for (int i = start; i < end && i < amps.length; i++) {
      if (amps[i] > peak) peak = amps[i];
    }
    return peak;
  }

  static AudioEventType _classifyEvent(double peak, int durationMs) {
    if (peak >= 0.75 && durationMs >= 800) return AudioEventType.snore;
    if (peak >= 0.70) return AudioEventType.environmentalNoise;
    return AudioEventType.movement;
  }
}
