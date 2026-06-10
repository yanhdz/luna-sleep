import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;

class MicrophonePermissionService {
  static const platform = MethodChannel('com.yansoft.luna/microphone');

  /// Request microphone permission.
  static Future<bool> requestMicrophonePermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final status = await Permission.microphone.request();
        final granted = status.isGranted;
        developer.log('[MicrophonePermissionService] Android permission request result: $granted');
        return granted;
      } catch (e) {
        developer.log('[MicrophonePermissionService] Android permission request error: $e', stackTrace: StackTrace.current);
        return false;
      }
    }

    try {
      developer.log('[MicrophonePermissionService] Requesting microphone permission via native channel');
      
      final bool result = await platform.invokeMethod<bool>('requestMicrophonePermission') ?? false;
      
      developer.log('[MicrophonePermissionService] Native result: $result');
      return result;
    } on PlatformException catch (e) {
      developer.log('[MicrophonePermissionService] Platform error: ${e.message}', stackTrace: StackTrace.current);
      return false;
    } catch (e) {
      developer.log('[MicrophonePermissionService] Unexpected error: $e', stackTrace: StackTrace.current);
      return false;
    }
  }

  /// Check current microphone permission status.
  static Future<bool> hasMicrophonePermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final status = await Permission.microphone.status;
        final granted = status.isGranted;
        developer.log('[MicrophonePermissionService] Android permission status: $granted');
        return granted;
      } catch (e) {
        developer.log('[MicrophonePermissionService] Android permission status error: $e', stackTrace: StackTrace.current);
        return false;
      }
    }

    try {
      developer.log('[MicrophonePermissionService] Checking microphone permission via native channel');
      
      final bool result = await platform.invokeMethod<bool>('hasMicrophonePermission') ?? false;
      
      developer.log('[MicrophonePermissionService] Permission status: $result');
      return result;
    } on PlatformException catch (e) {
      developer.log('[MicrophonePermissionService] Platform error: ${e.message}', stackTrace: StackTrace.current);
      return false;
    } catch (e) {
      developer.log('[MicrophonePermissionService] Unexpected error: $e', stackTrace: StackTrace.current);
      return false;
    }
  }
}
