import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'dart:io';

import '../../../data/models/recording_session.dart';

enum PlaybackStatus { idle, loading, playing, paused, completed, error }

class PlaybackState {
  final PlaybackStatus status;
  final Duration position;
  final Duration duration;
  final RecordingSession? session;
  final String? error;

  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.session,
    this.error,
  });

  PlaybackState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    RecordingSession? session,
    String? error,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      session: session ?? this.session,
      error: error,
    );
  }

  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }
}

class PlaybackNotifier
  extends AutoDisposeFamilyNotifier<PlaybackState, RecordingSession> {
  late final AudioPlayer _player;
  late StreamSubscription _positionSubscription;
  late StreamSubscription _playerStateSubscription;

  @override
  PlaybackState build(RecordingSession arg) {
    _player = AudioPlayer();
    
    _positionSubscription = _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });
    
    _playerStateSubscription = _player.playerStateStream.listen((ps) {
      if (ps.playing) {
        state = state.copyWith(status: PlaybackStatus.playing);
        return;
      }

      if (ps.processingState == ProcessingState.completed) {
        state = state.copyWith(status: PlaybackStatus.completed);
        return;
      }

      if (ps.processingState != ProcessingState.loading &&
          state.status == PlaybackStatus.playing) {
        state = state.copyWith(status: PlaybackStatus.paused);
      }
    });
    
    ref.onDispose(() async {
      await _positionSubscription.cancel();
      await _playerStateSubscription.cancel();
      await _player.stop();
      await _player.dispose();
    });
    
    return PlaybackState(session: arg);
  }

  Future<void> load() async {
    state = state.copyWith(status: PlaybackStatus.loading);
    try {
      final filePath = state.session!.audioFilePath;
      print('[Playback] ========== LOADING AUDIO ==========');
      print('[Playback] Original file path: $filePath');
      
      // Check if file exists
      final file = File(filePath);
      final exists = await file.exists();
      print('[Playback] File exists: $exists');
      
      if (exists) {
        final size = await file.length();
        final lastModified = await file.lastModified();
        print('[Playback] File size: $size bytes (${(size / 1024 / 1024).toStringAsFixed(2)} MB)');
        print('[Playback] Last modified: $lastModified');
      } else {
        print('[Playback] ERROR: File does not exist at path!');
        state = state.copyWith(
            status: PlaybackStatus.error, 
            error: 'Audio file not found: $filePath');
        return;
      }
      
      print('[Playback] Loading audio file from URI: $filePath');
      
      final duration = await _player.setFilePath(filePath);
      
      print('[Playback] File loaded successfully. Duration: $duration');
      state = state.copyWith(
        status: PlaybackStatus.idle,
        duration: duration ?? Duration.zero,
      );
    } catch (e, stackTrace) {
      print('[Playback] ERROR loading file: $e');
      print('[Playback] Stack trace: $stackTrace');
      state = state.copyWith(
          status: PlaybackStatus.error, 
          error: 'Failed to load audio: $e');
    }
  }

  Future<void> play() async {
    try {
      if (state.status == PlaybackStatus.completed) {
        await _player.seek(Duration.zero);
      }

      print('[Playback] Starting playback');
      state = state.copyWith(status: PlaybackStatus.playing, error: null);
      await _player.play();
    } catch (e) {
      print('[Playback] Error playing: $e');
      state = state.copyWith(
          status: PlaybackStatus.error,
          error: 'Failed to play: $e');
    }
  }

  Future<void> pause() async {
    state = state.copyWith(status: PlaybackStatus.paused, error: null);
    await _player.pause();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    state = state.copyWith(position: position);
  }
}

final playbackProvider = AutoDisposeNotifierProviderFamily<PlaybackNotifier,
  PlaybackState, RecordingSession>(PlaybackNotifier.new);
