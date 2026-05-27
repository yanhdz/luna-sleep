enum AudioEventType { snore, movement, environmentalNoise }

extension AudioEventTypeX on AudioEventType {
  String get label {
    switch (this) {
      case AudioEventType.snore:
        return 'Snore detected';
      case AudioEventType.movement:
        return 'Restless movement';
      case AudioEventType.environmentalNoise:
        return 'Environmental noise';
    }
  }

  String get icon {
    switch (this) {
      case AudioEventType.snore:
        return '😴';
      case AudioEventType.movement:
        return '🔄';
      case AudioEventType.environmentalNoise:
        return '🔊';
    }
  }
}

class AudioEvent {
  final String id;
  final DateTime timestamp;
  final AudioEventType type;
  final int durationMs;
  final double peakAmplitude;
  final int amplitudeStartIndex; // index into session amplitudes list
  final int amplitudeLength;
  final String? clipPath;

  const AudioEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.durationMs,
    required this.peakAmplitude,
    required this.amplitudeStartIndex,
    required this.amplitudeLength,
    this.clipPath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'type': type.name,
        'durationMs': durationMs,
        'peakAmplitude': peakAmplitude,
        'amplitudeStartIndex': amplitudeStartIndex,
        'amplitudeLength': amplitudeLength,
        'clipPath': clipPath,
      };

  factory AudioEvent.fromJson(Map<String, dynamic> json) => AudioEvent(
        id: json['id'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: AudioEventType.values.byName(json['type'] as String),
        durationMs: json['durationMs'] as int,
        peakAmplitude: (json['peakAmplitude'] as num).toDouble(),
        amplitudeStartIndex: json['amplitudeStartIndex'] as int,
        amplitudeLength: json['amplitudeLength'] as int,
        clipPath: json['clipPath'] as String?,
      );
}
