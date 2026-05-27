import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/recording_session.dart';

class RecordingRepository {
  RecordingRepository._();
  static final RecordingRepository instance = RecordingRepository._();

  static const String _sessionsFileName = 'sessions.json';

  Future<Directory> get _recordingsDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/luna_recordings');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> get _sessionsFile async {
    final base = await getApplicationDocumentsDirectory();
    return File('${base.path}/$_sessionsFileName');
  }

  Future<String> get newAudioFilePath async {
    final dir = await _recordingsDir;
    final name = 'luna_${DateTime.now().millisecondsSinceEpoch}.aac';
    return '${dir.path}/$name';
  }

  Future<List<RecordingSession>> loadAll() async {
    final file = await _sessionsFile;
    if (!await file.exists()) return [];
    try {
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => RecordingSession.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.startTime.compareTo(a.startTime));
    } catch (_) {
      return [];
    }
  }

  Future<void> save(RecordingSession session) async {
    final sessions = await loadAll();
    final idx = sessions.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      sessions[idx] = session;
    } else {
      sessions.insert(0, session);
    }
    await _persist(sessions);
  }

  Future<void> delete(String sessionId) async {
    final sessions = await loadAll();
    final session = sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw StateError('Session not found'),
    );
    // Delete audio file
    final audioFile = File(session.audioFilePath);
    if (await audioFile.exists()) await audioFile.delete();

    sessions.removeWhere((s) => s.id == sessionId);
    await _persist(sessions);
  }

  Future<void> deleteAll() async {
    final sessions = await loadAll();
    for (final s in sessions) {
      final f = File(s.audioFilePath);
      if (await f.exists()) await f.delete();
    }
    final file = await _sessionsFile;
    if (await file.exists()) await file.delete();
  }

  Future<void> _persist(List<RecordingSession> sessions) async {
    final file = await _sessionsFile;
    await file.writeAsString(
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }
}
