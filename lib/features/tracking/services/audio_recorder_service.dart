import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:record/record.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/amplitude_processor.dart';
import '../../../core/services/audio_amplitude_service.dart';

enum RecorderStatus { idle, recording, stopped }

class AudioRecorderService {
  AudioRecorderService._();
  static final AudioRecorderService instance = AudioRecorderService._();

  final AudioRecorder _recorder = AudioRecorder();
  RecorderStatus _status = RecorderStatus.idle;
  String? _currentFilePath;

  final List<double> _amplitudes = [];
  final _amplitudeController = StreamController<double>.broadcast();
  final _amplitudeListController =
      StreamController<List<double>>.broadcast();

  StreamSubscription<double>? _amplitudeStreamSubscription;

  RecorderStatus get status => _status;
  List<double> get amplitudes => List.unmodifiable(_amplitudes);
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  Stream<List<double>> get amplitudeListStream =>
      _amplitudeListController.stream;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> startRecording(String filePath) async {
    if (_status == RecorderStatus.recording) {
      print('[AudioRecorder] Already recording, ignoring start request');
      return;
    }

    _currentFilePath = filePath;
    _amplitudes.clear();

    try {
      print('[AudioRecorder] ========== STARTING RECORDING ==========');
      print('[AudioRecorder] Target file path: $filePath');
      
      // Check if directory exists
      final file = File(filePath);
      final dir = file.parent;
      print('[AudioRecorder] Directory: ${dir.path}');
      print('[AudioRecorder] Directory exists: ${await dir.exists()}');
      
      print('[AudioRecorder] Starting recording with config: AAC-LC, 64kbps, 44.1kHz, Mono');
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: filePath,
      );
      print('[AudioRecorder] Recording started successfully');
      print('[AudioRecorder] File path stored: $_currentFilePath');
      _status = RecorderStatus.recording;
      
      // Start listening to native amplitude stream
      await AudioAmplitudeService.startListening();
      _subscribeToAmplitudeStream();
    } catch (e) {
      print('[AudioRecorder] Error starting recording: $e');
      await AudioAmplitudeService.stopListening();
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    if (_status != RecorderStatus.recording) {
      print('[AudioRecorder] Not recording, ignoring stop request');
      return null;
    }
    
    print('[AudioRecorder] ========== STOPPING RECORDING ==========');
    print('[AudioRecorder] Stopping recording...');
    _amplitudeStreamSubscription?.cancel();
    _amplitudeStreamSubscription = null;
    
    try {
      await AudioAmplitudeService.stopListening();
      final path = await _recorder.stop();
      final finalPath = path ?? _currentFilePath;
      
      print('[AudioRecorder] Recording stopped. Returned path: $path');
      print('[AudioRecorder] Final path used: $finalPath');
      
      // Check if file exists and get size
      if (finalPath != null) {
        final file = File(finalPath);
        final exists = await file.exists();
        print('[AudioRecorder] File exists: $exists');
        
        if (exists) {
          final size = await file.length();
          print('[AudioRecorder] File size: $size bytes (${(size / 1024 / 1024).toStringAsFixed(2)} MB)');
        }
      }
      
      _status = RecorderStatus.stopped;
      print('[AudioRecorder] Status set to stopped');
      return finalPath;
    } catch (e) {
      print('[AudioRecorder] Error stopping recording: $e');
      rethrow;
    }
  }

  Future<void> dispose() async {
    _amplitudeStreamSubscription?.cancel();
    await _recorder.dispose();
    await _amplitudeController.close();
    await _amplitudeListController.close();
    await AudioAmplitudeService.dispose();
  }

  void reset() {
    _amplitudes.clear();
    _amplitudeStreamSubscription?.cancel();
    _amplitudeStreamSubscription = null;
    _status = RecorderStatus.idle;
  }

  void _subscribeToAmplitudeStream() {
    developer.log('[AudioRecorder] Subscribing to amplitude stream');
    
    _amplitudeStreamSubscription = AudioAmplitudeService.amplitudeStream.listen(
      (dbfs) {
        if (_status != RecorderStatus.recording) return;
        
        try {
          developer.log('[AudioRecorder] Amplitude: $dbfs dBFS');
          final normalized = AmplitudeProcessor.normalize(dbfs);
          
          _amplitudes.add(normalized);
          if (_amplitudes.length > AppConstants.waveformHistoryMax) {
            _amplitudes.removeAt(0);
          }

          _amplitudeController.add(normalized);
          _amplitudeListController.add(List.unmodifiable(_amplitudes));
        } catch (e) {
          developer.log('[AudioRecorder] Error: $e');
        }
      },
      onError: (e) {
        developer.log('[AudioRecorder] Stream error: $e');
      },
    );
  }
}

