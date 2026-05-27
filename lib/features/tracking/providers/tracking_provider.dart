import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/microphone_permission_service.dart';
import '../../../data/models/recording_session.dart';
import '../../../data/repositories/recording_repository.dart';
import '../../../core/utils/amplitude_processor.dart';
import '../services/audio_recorder_service.dart';

// ─── Sessions provider ────────────────────────────────────────────────────────

class SessionsNotifier extends AsyncNotifier<List<RecordingSession>> {
  @override
  Future<List<RecordingSession>> build() =>
      RecordingRepository.instance.loadAll();

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(RecordingRepository.instance.loadAll);
  }

  Future<void> delete(String id) async {
    await RecordingRepository.instance.delete(id);
    await reload();
  }

  Future<void> deleteAll() async {
    await RecordingRepository.instance.deleteAll();
    await reload();
  }
}

final sessionsProvider =
    AsyncNotifierProvider<SessionsNotifier, List<RecordingSession>>(
        SessionsNotifier.new);

// ─── Tracking provider ────────────────────────────────────────────────────────

enum TrackingStatus { idle, requestingPermission, recording, processing, done }

class TrackingState {
  final TrackingStatus status;
  final RecordingSession? currentSession;
  final double currentAmplitude;
  final List<double> recentAmplitudes; // last N for live waveform
  final Duration elapsed;
  final String? errorMessage;

  const TrackingState({
    this.status = TrackingStatus.idle,
    this.currentSession,
    this.currentAmplitude = 0.0,
    this.recentAmplitudes = const [],
    this.elapsed = Duration.zero,
    this.errorMessage,
  });

  TrackingState copyWith({
    TrackingStatus? status,
    RecordingSession? currentSession,
    double? currentAmplitude,
    List<double>? recentAmplitudes,
    Duration? elapsed,
    String? errorMessage,
  }) {
    return TrackingState(
      status: status ?? this.status,
      currentSession: currentSession ?? this.currentSession,
      currentAmplitude: currentAmplitude ?? this.currentAmplitude,
      recentAmplitudes: recentAmplitudes ?? this.recentAmplitudes,
      elapsed: elapsed ?? this.elapsed,
      errorMessage: errorMessage,
    );
  }
}

class TrackingNotifier extends Notifier<TrackingState> {
  final _recorder = AudioRecorderService.instance;
  final _repo = RecordingRepository.instance;
  final _uuid = const Uuid();
  Timer? _elapsedTimer;
  StreamSubscription<double>? _ampSub;
  StreamSubscription<List<double>>? _listSub;

  @override
  TrackingState build() => const TrackingState();

  Future<void> startTracking() async {
    print('[Tracking] ========== START TRACKING PRESSED ==========');
    print('[Tracking] startTracking() called');
    state = state.copyWith(status: TrackingStatus.requestingPermission);
    developer.log('[Tracking] State updated to requestingPermission');

    try {
      developer.log('[Permission] Checking current microphone permission status...');
      bool hasPermission = await MicrophonePermissionService.hasMicrophonePermission();
      print('[Permission] Current status: hasPermission=$hasPermission');
      
      // If already granted, proceed directly
      if (hasPermission) {
        print('[Permission] Microphone permission already granted');
        await _startRecordingSession();
        return;
      }
      
      print('[Permission] Permission not yet granted, requesting now via native channel...');
      final bool granted = await MicrophonePermissionService.requestMicrophonePermission();
      print('[Permission] Native request completed. Granted: $granted');

      if (granted) {
        developer.log('[Permission] Permission GRANTED!');
        await _startRecordingSession();
      } else {
        developer.log('[Permission] Permission denied by user');
        state = state.copyWith(
          status: TrackingStatus.idle,
          errorMessage: 'Microphone permission required. Please grant access to start tracking.',
        );
      }
    } catch (e, stackTrace) {
      developer.log('[Error] Exception in startTracking: $e', stackTrace: stackTrace);
      state = state.copyWith(
        status: TrackingStatus.idle,
        errorMessage: 'Error requesting permission: ${e.toString()}',
      );
    }
  }

  Future<void> _startRecordingSession() async {
    try {
      final filePath = await _repo.newAudioFilePath;
      print('[Recording] Got audio file path: $filePath');

      final session = RecordingSession(
        id: _uuid.v4(),
        startTime: DateTime.now(),
        audioFilePath: filePath,
        amplitudes: const [],
        events: const [],
      );

      print('[Recording] Starting audio recorder...');
      await _recorder.startRecording(filePath);
      print('[Recording] Audio recorder started successfully');

      state = state.copyWith(
        status: TrackingStatus.recording,
        currentSession: session,
        elapsed: Duration.zero,
        errorMessage: null,
      );

      _startElapsedTimer();
      _subscribeToAmplitudes();
      print('[Tracking] Recording session started');
    } catch (e, stackTrace) {
      print('[Error] Exception in _startRecordingSession: $e');
      developer.log('[Error] Exception in _startRecordingSession: $e', stackTrace: stackTrace);
      state = state.copyWith(
        status: TrackingStatus.idle,
        errorMessage: 'Error starting recording: ${e.toString()}',
      );
    }
  }

  Future<void> stopTracking() async {
    if (state.status != TrackingStatus.recording) return;

    print('[Tracking] ========== STOP TRACKING PRESSED ==========');
    print('[Tracking] stopTracking() called');
    state = state.copyWith(status: TrackingStatus.processing);

    _elapsedTimer?.cancel();
    _ampSub?.cancel();
    _listSub?.cancel();

    await _recorder.stopRecording();
    print('[Recording] Recorder stopped, processing data...');

    final allAmplitudes = _recorder.amplitudes.toList();
    print('[Recording] Total amplitudes captured: ${allAmplitudes.length}');
    
    final events = AmplitudeProcessor.detectEvents(
      allAmplitudes,
      state.currentSession!.startTime,
    );
    print('[Recording] Events detected: ${events.length}');

    final finishedSession = state.currentSession!.copyWith(
      endTime: DateTime.now(),
      amplitudes: allAmplitudes,
      events: events,
    );

    await _repo.save(finishedSession);
    print('[Recording] Session saved to repository');
    print('[Recording] Final audio file path: ${finishedSession.audioFilePath}');
    
    _recorder.reset();

    state = state.copyWith(
      status: TrackingStatus.done,
      currentSession: finishedSession,
    );
    print('[Tracking] Recording session completed and saved');
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  void resetToIdle() {
    _recorder.reset();
    state = const TrackingState();
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == TrackingStatus.recording) {
        state = state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1));
      }
    });
  }

  void _subscribeToAmplitudes() {
    _ampSub = _recorder.amplitudeStream.listen((amp) {
      state = state.copyWith(currentAmplitude: amp);
    });

    _listSub = _recorder.amplitudeListStream.listen((list) {
      final recent = list.length > 80
          ? list.sublist(list.length - 80)
          : list;
      state = state.copyWith(recentAmplitudes: recent);
    });
  }
}

final trackingProvider = NotifierProvider<TrackingNotifier, TrackingState>(
    TrackingNotifier.new);
