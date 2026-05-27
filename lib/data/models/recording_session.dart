import 'audio_event.dart';

class RecordingSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String audioFilePath;
  final List<double> amplitudes; // normalized 0..1, sampled every 100ms
  final List<AudioEvent> events;

  const RecordingSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.audioFilePath,
    required this.amplitudes,
    required this.events,
  });

  Duration get duration {
    if (endTime == null) return Duration.zero;
    return endTime!.difference(startTime);
  }

  bool get isComplete => endTime != null;

  double get avgAmplitude {
    if (amplitudes.isEmpty) return 0.0;
    return amplitudes.reduce((a, b) => a + b) / amplitudes.length;
  }

  double get noisyPercent {
    if (amplitudes.isEmpty) return 0.0;
    final loud = amplitudes.where((a) => a >= 0.4).length;
    return (loud / amplitudes.length) * 100.0;
  }

  int get snoreCount => events.where((e) => e.type == AudioEventType.snore).length;

  int get peakCount {
    int count = 0;
    bool wasHigh = false;
    for (final a in amplitudes) {
      if (a >= 0.7 && !wasHigh) {
        count++;
        wasHigh = true;
      } else if (a < 0.7) {
        wasHigh = false;
      }
    }
    return count;
  }

  RecordingSession copyWith({
    DateTime? endTime,
    List<double>? amplitudes,
    List<AudioEvent>? events,
    String? audioFilePath,
  }) {
    return RecordingSession(
      id: id,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      amplitudes: amplitudes ?? this.amplitudes,
      events: events ?? this.events,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'audioFilePath': audioFilePath,
        'amplitudes': amplitudes,
        'events': events.map((e) => e.toJson()).toList(),
      };

  factory RecordingSession.fromJson(Map<String, dynamic> json) =>
      RecordingSession(
        id: json['id'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        audioFilePath: json['audioFilePath'] as String,
        amplitudes: (json['amplitudes'] as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList(),
        events: (json['events'] as List<dynamic>)
            .map((e) => AudioEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
