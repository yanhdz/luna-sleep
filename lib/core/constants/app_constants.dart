class AppConstants {
  AppConstants._();

  // Recording
  static const int amplitudeSampleRateMs = 100;
  static const int maxRecordingHours = 8;
  static const int maxRecordingSeconds = maxRecordingHours * 3600;

  // Snore detection thresholds (dBFS – negative scale, 0 = max loudness)
  static const double snoreThresholdDb = -30.0;
  static const double environmentalNoiseThresholdDb = -25.0;
  static const double movementThresholdDb = -20.0;
  static const int minSnoreDurationMs = 500;   // must be loud for ≥500ms
  static const int minEventGapMs = 2000;       // gap before new event

  // Waveform display
  static const int waveformVisibleBars = 120;
  static const int waveformHistoryMax = 50000; // ~83 min at 100ms

  // Storage
  static const String sessionsBoxKey = 'sessions';
  static const String settingsBoxKey = 'settings';
  static const String audioSubdir = 'luna_recordings';

  // Dummy / demo data
  static const bool showDemoHints = true;
}
