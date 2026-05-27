import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';

/// Native audio amplitude capture service using iOS AVAudioEngine
/// Uses EventChannel for efficient real-time amplitude streaming
class AudioAmplitudeService {
  static const _amplitudeChannel = EventChannel('com.yansoft.luna/amplitude');
  static StreamSubscription<dynamic>? _streamSubscription;
  static StreamController<double>? _amplitudeController;

  /// Get stream of amplitude readings in real-time
  /// Returns Stream<double> with normalized amplitude values (dBFS)
  static Stream<double> get amplitudeStream {
    _amplitudeController ??= StreamController<double>.broadcast();
    return _amplitudeController!.stream;
  }

  /// Start listening to native amplitude events
  static Future<void> startListening() async {
    try {
      developer.log('[AudioAmplitude] Starting amplitude stream listener');
      
      // Cancel existing subscription if any
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      
      // Recreate controller if it was closed
      if (_amplitudeController == null || _amplitudeController!.isClosed) {
        _amplitudeController = StreamController<double>.broadcast();
      }
      
      _streamSubscription = _amplitudeChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map && !(_amplitudeController?.isClosed ?? true)) {
            final amplitude = (event['amplitude'] as num?)?.toDouble() ?? -160.0;
            developer.log('[AudioAmplitude] Received: $amplitude dBFS');
            try {
              _amplitudeController?.add(amplitude);
            } catch (e) {
              developer.log('[AudioAmplitude] Error adding amplitude: $e');
            }
          }
        },
        onError: (error) {
          developer.log('[AudioAmplitude] Stream error: $error');
        },
      );
      
      developer.log('[AudioAmplitude] Stream listener started');
    } catch (e) {
      developer.log('[AudioAmplitude] Error starting listener: $e');
    }
  }

  /// Stop listening to amplitude events
  static Future<void> stopListening() async {
    try {
      await _streamSubscription?.cancel();
      _streamSubscription = null;
      developer.log('[AudioAmplitude] Stream listener stopped');
    } catch (e) {
      developer.log('[AudioAmplitude] Error stopping listener: $e');
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    await stopListening();
    // Don't close the controller - just clear listeners by creating a new one on next use
    _amplitudeController = null;
  }
}

