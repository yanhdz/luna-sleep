import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:record/record.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/amplitude_processor.dart';

enum RecorderStatus { idle, recording, stopped }

class AudioRecorderService {
  AudioRecorderService._();
  static final AudioRecorderService instance = AudioRecorderService._();

  AudioRecorder? _recorder;
  RecorderStatus _status = RecorderStatus.idle;
  String? _currentFilePath;

  final List<double> _amplitudes = [];
  final _dbfsController = StreamController<double>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();
  final _amplitudeListController =
      StreamController<List<double>>.broadcast();

  StreamSubscription<Amplitude>? _amplitudeStreamSubscription;

  RecorderStatus get status => _status;
  List<double> get amplitudes => List.unmodifiable(_amplitudes);
  Stream<double> get dbfsStream => _dbfsController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  Stream<List<double>> get amplitudeListStream =>
      _amplitudeListController.stream;

  AudioRecorder get _activeRecorder => _recorder ??= AudioRecorder();

  Future<bool> hasPermission() => _activeRecorder.hasPermission();

  Future<void> startRecording(String filePath) async {
    if (_status == RecorderStatus.recording) {
      print('[AudioRecorder] Already recording, ignoring start request');
      return;
    }

    await _cancelAmplitudeSubscription();
    await _disposeRecorder();
    _recorder = AudioRecorder();
    final recorder = _recorder!;

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
      await recorder.start(
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

      _subscribeToAmplitudeStream(recorder);
    } catch (e) {
      print('[AudioRecorder] Error starting recording: $e');
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
    final recorder = _recorder;
    if (recorder == null) {
      _status = RecorderStatus.stopped;
      return _currentFilePath;
    }
    await _cancelAmplitudeSubscription();
    
    try {
      final path = await recorder.stop();
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
    await _cancelAmplitudeSubscription();
    await _disposeRecorder();
    await _dbfsController.close();
    await _amplitudeController.close();
    await _amplitudeListController.close();
  }

  Future<void> reset() async {
    _amplitudes.clear();
    await _cancelAmplitudeSubscription();
    await _disposeRecorder();
    _currentFilePath = null;
    _status = RecorderStatus.idle;
  }

  Future<void> _cancelAmplitudeSubscription() async {
    await _amplitudeStreamSubscription?.cancel();
    _amplitudeStreamSubscription = null;
  }

  Future<void> _disposeRecorder() async {
    await _recorder?.dispose();
    _recorder = null;
  }

  void _subscribeToAmplitudeStream(AudioRecorder recorder) {
    developer.log('[AudioRecorder] Subscribing to amplitude stream');
    
    _amplitudeStreamSubscription = recorder
        .onAmplitudeChanged(
          const Duration(milliseconds: AppConstants.amplitudeSampleRateMs),
        )
        .listen(
      (amplitude) {
        if (_status != RecorderStatus.recording || !identical(_recorder, recorder)) {
          return;
        }
        
        try {
          final dbfs = amplitude.current;
          developer.log('[AudioRecorder] Amplitude: $dbfs dBFS');
          final normalized = AmplitudeProcessor.normalize(dbfs);
          
          _dbfsController.add(dbfs);
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

