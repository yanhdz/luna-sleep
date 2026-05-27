import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class MicrophonePermissionService {
  static const platform = MethodChannel('com.yansoft.luna/microphone');

  /// Request microphone permission using native iOS implementation
  static Future<bool> requestMicrophonePermission() async {
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

  /// Check current microphone permission status using native implementation
  static Future<bool> hasMicrophonePermission() async {
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
