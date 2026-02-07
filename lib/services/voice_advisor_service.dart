import 'package:flutter_tts/flutter_tts.dart';
import 'driving_advisor_service.dart';

/// Service that provides voice announcements for driving advisories
class VoiceAdvisorService {
  final FlutterTts _tts = FlutterTts();
  bool _isEnabled = true;
  bool _isSpeaking = false;

  // Track last announced advisory to prevent repetition
  final Map<String, DateTime> _lastAnnounced = {};

  // Minimum time between repeating the same advisory
  static const Duration _infoCooldown = Duration(seconds: 45);
  static const Duration _warningCooldown = Duration(seconds: 30);
  static const Duration _criticalCooldown = Duration(seconds: 15);

  VoiceAdvisorService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    // Configure TTS settings
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5); // Slightly slower for clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    // Set up handlers
    _tts.setStartHandler(() {
      _isSpeaking = true;
    });

    _tts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      print('TTS Error: $msg');
    });

    // Welcome announcement
    await Future.delayed(const Duration(milliseconds: 500));
    await _speak('Welcome to O B D Dashboard. Voice advisor ready.');
  }

  /// Enable voice announcements
  void enable() {
    _isEnabled = true;
  }

  /// Disable voice announcements
  void disable() {
    _isEnabled = false;
    stop();
  }

  /// Check if voice is enabled
  bool get isEnabled => _isEnabled;

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Stop current speech
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  /// Announce a driving advisory
  Future<void> announceAdvisory(DrivingAdvisory advisory) async {
    if (!_isEnabled || _isSpeaking) return;

    // Check if we should announce this advisory
    if (!_shouldAnnounce(advisory)) return;

    // Clean message for speech (remove emojis and special characters)
    final cleanMessage = _cleanMessageForSpeech(advisory.message);

    // Speak the advisory
    await _speak(cleanMessage);

    // Record announcement time
    _lastAnnounced[advisory.message] = DateTime.now();
  }

  /// Announce the top priority advisory from a list
  Future<void> announceTopAdvisory(List<DrivingAdvisory> advisories) async {
    if (!_isEnabled || _isSpeaking || advisories.isEmpty) return;

    // Sort all advisories by severity (critical > warning > info)
    final sortedAdvisories = List<DrivingAdvisory>.from(advisories);
    sortedAdvisories.sort((a, b) {
      final severityOrder = {
        AdvisorySeverity.critical: 0,
        AdvisorySeverity.warning: 1,
        AdvisorySeverity.info: 2,
      };
      return severityOrder[a.severity]!.compareTo(severityOrder[b.severity]!);
    });

    // Announce the highest priority advisory
    await announceAdvisory(sortedAdvisories.first);
  }

  /// Check if an advisory should be announced based on cooldown
  bool _shouldAnnounce(DrivingAdvisory advisory) {
    final lastTime = _lastAnnounced[advisory.message];
    if (lastTime == null) return true;

    Duration cooldown;
    switch (advisory.severity) {
      case AdvisorySeverity.critical:
        cooldown = _criticalCooldown;
        break;
      case AdvisorySeverity.warning:
        cooldown = _warningCooldown;
        break;
      case AdvisorySeverity.info:
        cooldown = _infoCooldown;
        break;
    }

    return DateTime.now().difference(lastTime) >= cooldown;
  }

  /// Clean message for text-to-speech by removing emojis and special chars
  String _cleanMessageForSpeech(String message) {
    // Remove common emojis
    var cleaned = message
        .replaceAll('🚨', 'Alert!')
        .replaceAll('⚠️', 'Warning!')
        .replaceAll('❄️', '')
        .replaceAll('⛽', '')
        .replaceAll('🔋', '')
        .replaceAll('ℹ️', '')
        .replaceAll('✅', '');

    // Remove other emojis using regex
    cleaned = cleaned.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
        unicode: true,
      ),
      '',
    );

    return cleaned.trim();
  }

  /// Speak text directly
  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    await _tts.speak(text);
  }

  /// Test the voice service
  Future<void> testVoice() async {
    await _speak('Voice advisor system ready');
  }

  /// Clear announcement history (useful when reconnecting or starting fresh)
  void clearHistory() {
    _lastAnnounced.clear();
  }

  /// Dispose of resources
  void dispose() {
    _tts.stop();
  }
}
