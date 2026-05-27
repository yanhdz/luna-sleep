import Flutter
import UIKit
import AVFoundation

// ─── Audio Engine Manager for amplitude capture ─────────────────────────────

class AudioEngineManager {
  static let shared = AudioEngineManager()
  private let engine = AVAudioEngine()
  private var isMonitoring = false
  private var eventSink: FlutterEventSink?
  
  func setEventSink(_ sink: FlutterEventSink?) {
    self.eventSink = sink
  }
  
  func startMonitoring() {
    guard !isMonitoring else { return }
    isMonitoring = true
    
    let inputNode = engine.inputNode
    let format = inputNode.outputFormat(forBus: 0)
    
    print("[AudioEngine] Input format: \(format.sampleRate) Hz, \(format.channelCount) channels")
    
    // Install a tap to monitor input and send events
    // Use nil as format to let the tap adapt to the input node's format
    do {
      try inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
        guard let self = self else { return }
        
        // Calculate RMS (Root Mean Square) for amplitude
        guard let floatData = buffer.floatChannelData else { return }
        let channelData = floatData.pointee
        let frameLength = Int(buffer.frameLength)
        
        var sum: Float = 0
        for i in 0..<frameLength {
          let value = channelData[i]
          sum += value * value
        }
        
        let rms = sqrt(sum / Float(frameLength))
        // Convert to dBFS (20 * log10(rms))
        let dbfs = 20 * log10(rms == 0 ? 0.0001 : rms)
        
        // Send event to Dart on main thread
        DispatchQueue.main.async {
          self.eventSink?(["amplitude": dbfs, "rms": rms])
        }
      }
    } catch {
      print("[AudioEngine] Error installing tap: \(error)")
      return
    }
    
    do {
      try engine.start()
      print("[AudioEngine] Started monitoring")
    } catch {
      print("[AudioEngine] Error starting engine: \(error)")
    }
  }
  
  func stopMonitoring() {
    guard isMonitoring else { return }
    isMonitoring = false
    
    engine.inputNode.removeTap(onBus: 0)
    engine.stop()
    print("[AudioEngine] Stopped monitoring")
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure AVAudioSession for recording AND playback
    let audioSession = AVAudioSession.sharedInstance()
    do {
      // Set category to allow both recording and playback
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .duckOthers])
      try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
      print("[AppDelegate] AVAudioSession configured for playback and recording")
    } catch {
      print("[AppDelegate] Error setting up AVAudioSession: \(error)")
    }
    
    let controller = window?.rootViewController as! FlutterViewController
    
    // ─── Microphone permissions method channel ───
    let microphoneChannel = FlutterMethodChannel(
      name: "com.yansoft.luna/microphone",
      binaryMessenger: controller.binaryMessenger
    )
    
    microphoneChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "requestMicrophonePermission":
        self.requestMicrophonePermission(result: result)
      case "hasMicrophonePermission":
        self.hasMicrophonePermission(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    // ─── Amplitude events stream ───
    let amplitudeChannel = FlutterEventChannel(
      name: "com.yansoft.luna/amplitude",
      binaryMessenger: controller.binaryMessenger
    )
    
    amplitudeChannel.setStreamHandler(AudioAmplitudeStreamHandler())
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func requestMicrophonePermission(result: @escaping FlutterResult) {
    let audioSession = AVAudioSession.sharedInstance()
    
    // Request microphone permission
    audioSession.requestRecordPermission { granted in
      DispatchQueue.main.async {
        print("[AppDelegate] Microphone permission requested. Granted: \(granted)")
        result(granted)
      }
    }
  }
  
  private func hasMicrophonePermission(result: @escaping FlutterResult) {
    let status = AVAudioSession.sharedInstance().recordPermission
    let hasPermission = status == .granted
    print("[AppDelegate] Checking microphone permission. Status: \(status.rawValue), Has permission: \(hasPermission)")
    result(hasPermission)
  }
}

// ─── Stream Handler for Amplitude Events ─────────────────────────────────────

class AudioAmplitudeStreamHandler: NSObject, FlutterStreamHandler {
  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    print("[AudioAmplitude] Stream listener attached")
    AudioEngineManager.shared.setEventSink(events)
    AudioEngineManager.shared.startMonitoring()
    return nil
  }
  
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    print("[AudioAmplitude] Stream listener detached")
    AudioEngineManager.shared.setEventSink(nil)
    AudioEngineManager.shared.stopMonitoring()
    return nil
  }
}

