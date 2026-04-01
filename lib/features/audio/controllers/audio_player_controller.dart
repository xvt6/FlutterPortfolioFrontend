import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:rxdart/rxdart.dart';
import '../../../core/models/audio.dart';
import '../../../core/api/api_service.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

class AudioPlayerController with ChangeNotifier {
  AudioPlayer? _player;
  final ApiService _apiService = ApiService();
  Audio? _currentAudio;
  bool _isInitialized = false;

  AudioPlayerController() {
    _init();
  }

  Future<void> _init() async {
    try {
      // Ensure we're not initializing too early on Web
      await Future.delayed(Duration.zero);
      _player = AudioPlayer();
      _isInitialized = true;
      notifyListeners();

      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint("AudioPlayerController initialization error: $e");
    }
  }

  bool get isInitialized => _isInitialized && _player != null;
  Audio? get currentAudio => _currentAudio;
  AudioPlayer get player => _player!;

  Stream<PositionData> get positionDataStream {
    final p = _player;
    if (p == null) {
      return Stream.value(PositionData(Duration.zero, Duration.zero, Duration.zero));
    }
    return Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        p.positionStream,
        p.bufferedPositionStream,
        p.durationStream,
        (position, bufferedPosition, duration) => PositionData(
            position, bufferedPosition, duration ?? Duration.zero));
  }

  Future<void> playAudio(Audio audio) async {
    if (!_isInitialized || _player == null) {
      debugPrint("AudioPlayer not initialized yet");
      return;
    }

    if (_currentAudio?.fileIdentifier == audio.fileIdentifier) {
      if (_player!.playing) {
        await _player!.pause();
      } else {
        await _player!.play();
      }
      notifyListeners();
      return;
    }

    _currentAudio = audio;
    notifyListeners();

    try {
      final url = _apiService.getAudioStreamUrl(audio.fileIdentifier);
      await _player!.setUrl(url);
      await _player!.play();
    } catch (e) {
      debugPrint("Error loading audio stream: $e");
      _currentAudio = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> seek(Duration position) async {
    await _player?.seek(position);
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }
}
