import 'dart:async';

// import 'package:audio_session/audio_session.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_soloud_test/audio/data/music_player.dart';
import 'package:flutter_soloud_test/audio/data/sfx_player.dart';
import 'package:flutter_soloud_test/audio/model/sfx.dart';
import 'package:logging/logging.dart';
// import 'package:synchronized/extension.dart';

class AudioRepository {
  static final _log = Logger('AudioRepository');

  final Completer<bool> _initCompleter = Completer<bool>();
  // late final AudioSession _audioSession;
  final MusicPlayer _musicPlayer = MusicPlayer();
  final SfxPlayer _sfxPlayer = SfxPlayer();

  // bool _audioSessionActive = false;
  bool _musicOn = false;
  bool _soundsOn = false;

  AudioRepository() {
    unawaited(_init());
  }

  Future<void> _init() async {
    // try {
    //   _audioSession = await AudioSession.instance;
    //   await _audioSession.configure(const AudioSessionConfiguration(
    //     avAudioSessionCategory: AVAudioSessionCategory.ambient,
    //     avAudioSessionMode: AVAudioSessionMode.defaultMode,
    //     avAudioSessionSetActiveOptions:
    //         AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
    //     androidAudioAttributes: AndroidAudioAttributes(
    //       contentType: AndroidAudioContentType.sonification,
    //       flags: AndroidAudioFlags.none,
    //       usage: AndroidAudioUsage.game,
    //     ),
    //     androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    //     androidWillPauseWhenDucked: true,
    //   ));
    // } catch (error, stacktrace) {
    //   _log.severe('Error initializing AudioSession.', error, stacktrace);
    //   _initCompleter.complete(false);
    //   return;
    // }

    try {
      await SoLoud.instance.init(
        // We only play a finite number of tracks from assets.
        automaticCleanup: false,
        channels: Channels.stereo,
      );
    } catch (error, stacktrace) {
      _log.severe('Error initializing SoLoud.', error, stacktrace);
      _initCompleter.complete(false);
      return;
    }

    await _sfxPlayer.init();

    _initCompleter.complete(true);
  }

  Future<void> setMusicOn(bool musicOn) async {
    if (!(await _initCompleter.future)) return;
    if (_musicOn == musicOn) return;

    _musicOn = musicOn;

    // await _activateAudioSession(_musicOn);

    if (_musicOn) {
      await _musicPlayer.resume();
    } else {
      _musicPlayer.pause();
    }
  }

  Future<void> setSoundsOn(bool soundsOn) async {
    if (!(await _initCompleter.future)) return;
    if (_soundsOn == soundsOn) return;

    _soundsOn = soundsOn;
    // Stop any SFX when state changes.
    await _sfxPlayer.stop();
  }

  /// Plays a single sound effect. Returns when the sound finishes playing.
  Future<void> playSfx(Sfx sfx) async {
    if (!(await _initCompleter.future)) return;

    if (!_soundsOn) {
      _log.info(
        () => 'Ignoring playing sound ($sfx) because sounds are turned off.',
      );
      return;
    }

    // await _activateAudioSession(true);
    await _sfxPlayer.play(sfx);
    // if (!_musicOn) {
    //   await _activateAudioSession(false);
    // }
  }

  // Future<void> _activateAudioSession(bool active) async {
  //   await synchronized(() async {
  //     if (_audioSessionActive == active) return;

  //     try {
  //       final success = await _audioSession.setActive(active);
  //       if (!success) {
  //         _log.warning(
  //             'Failed ${active ? 'activating' : 'deactivating'} AudioSession.');
  //       }
  //     } catch (error, stacktrace) {
  //       _log.warning(
  //           'Error ${active ? 'activating' : 'deactivating'} AudioSession.',
  //           error,
  //           stacktrace);
  //     }

  //     _audioSessionActive = active;
  //   });
  // }

  Future<void> dispose() async {
    if (!(await _initCompleter.future)) return;

    await _musicPlayer.stop();
    await _sfxPlayer.stop();
    await _sfxPlayer.dispose();
  }
}
