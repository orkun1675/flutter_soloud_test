import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_soloud_test/audio/model/music.dart';
import 'package:logging/logging.dart';

final class MusicPlayer {
  static final _log = Logger('MusicPlayer');

  final Random _random = Random();

  bool _playing = false;
  AudioSource? _audioSource;
  SoundHandle? _handle;
  Music? _previousMusic;

  MusicPlayer();

  /// Starts playing music if not already playing.
  /// Returns when music starts playing.
  Future<void> resume() async {
    if (_playing) return; // Already playing

    _log.info('Resuming music.');
    _playing = true;

    await _playMusic();
  }

  /// Pauses the playing music if any.
  /// Returns when music is paused.
  void pause() {
    if (!_playing) return; // Not playing

    _log.info('Pausing music.');

    _playing = false;

    final handle = _handle;
    if (handle != null) {
      SoLoud.instance.setPause(handle, true);
    }
  }

  /// Stops the playing music if any.
  /// Returns when music stops playing.
  Future<void> stop() async {
    if (!_playing) return; // Not playing

    _log.info('Stopping music.');

    _playing = false;

    final handle = _handle;
    if (handle != null) {
      await SoLoud.instance.stop(handle);
    }

    final audioSource = _audioSource;
    if (audioSource != null) {
      dispose(audioSource);
    }
  }

  Future<void> _playMusic() async {
    if (!_playing) return;

    final previousHandle = _handle;
    if (previousHandle != null) {
      SoLoud.instance.setPause(previousHandle, false);
      _log.fine('Resumed previous track.');
      return;
    }

    final musicOptions = Music.values.length >= 2
        ? Music.values.where((music) => music != _previousMusic)
        : Music.values;
    final music = musicOptions.elementAt(_random.nextInt(musicOptions.length));

    final AudioSource audioSource;
    try {
      audioSource = await SoLoud.instance.loadAsset(
        music.assetPath,
        mode: LoadMode.disk,
        assetBundle: rootBundle,
      );
    } catch (error, stacktrace) {
      _log.warning(
        'Error loading music from ${music.assetPath}.',
        error,
        stacktrace,
      );
      _playing = false;
      return;
    }

    final SoundHandle handle;
    try {
      handle = await SoLoud.instance.play(audioSource, volume: music.volume);
    } catch (error, stacktrace) {
      _log.warning('Error playing music ${music.name}.', error, stacktrace);
      _playing = false;
      dispose(audioSource);
      return;
    }

    _audioSource = audioSource;
    _handle = handle;
    _previousMusic = music;

    unawaited(_loopNextMusic(audioSource));
  }

  Future<void> _loopNextMusic(final AudioSource audioSource) async {
    await audioSource.allInstancesFinished.first;
    dispose(audioSource);
    _handle = null;
    _audioSource = null;
    await _playMusic();
  }

  void dispose(final AudioSource audioSource) {
    unawaited(
      SoLoud.instance.disposeSource(audioSource).catchError((
        error,
        stacktrace,
      ) {
        _log.warning('Error disposing music.', error, stacktrace);
      }),
    );
  }
}
