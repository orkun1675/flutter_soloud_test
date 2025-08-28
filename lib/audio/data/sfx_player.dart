import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_soloud_test/audio/model/sfx.dart';
import 'package:logging/logging.dart';

final class SfxPlayer {
  static final _log = Logger('SfxPlayer');

  final Random _random = Random();
  final Completer<void> _initCompleter = Completer<void>();
  final Map<Sfx, List<AudioSource>> _audioSources = {};
  final Set<SoundHandle> _playingHandles = {};

  SfxPlayer();

  /// Must be called and awaited for before using the player.
  Future<void> init() async {
    final stopwatch = Stopwatch()..start();
    for (final sfx in Sfx.values) {
      for (final assetPath in sfx.assetPaths) {
        try {
          final bytes = await _getAssetBytes(assetPath);
          final audioSource = await SoLoud.instance.loadMem(
            assetPath,
            bytes,
            mode: LoadMode.memory,
          );
          _audioSources.putIfAbsent(sfx, () => []).add(audioSource);
        } catch (error, stacktrace) {
          _log.warning('Error loading sfx from $assetPath.', error, stacktrace);
        }
      }
    }
    _initCompleter.complete();
    _log.info(
      'SfxPlayer audio sources loaded in '
      '${stopwatch.elapsed.inMilliseconds}ms.',
    );
  }

  /// Plays a single sound effect. Returns when the sound finishes playing.
  Future<void> play(Sfx sfx) async {
    await _initCompleter.future;

    final audioSources = _audioSources[sfx];
    if (audioSources == null || audioSources.isEmpty) {
      _log.warning('No audio sources found for $sfx');
      return;
    }

    final audioSource = audioSources[_random.nextInt(audioSources.length)];
    _log.info(
      () =>
          'Playing sound: ${sfx.name}. Chosen audio: ${audioSource.toString()}',
    );

    final SoundHandle currentHandle;
    try {
      currentHandle = await SoLoud.instance.play(
        audioSource,
        volume: sfx.volume,
      );
    } catch (error, stacktrace) {
      _log.warning('Error playing sfx ${sfx.name}.', error, stacktrace);
      return;
    }

    _playingHandles.add(currentHandle);

    try {
      await audioSource.soundEvents
          .firstWhere(
            (soundEvent) =>
                soundEvent.handle == currentHandle &&
                soundEvent.event == SoundEventType.handleIsNoMoreValid,
          )
          // Assume all sound effects are less than 10 seconds.
          .timeout(const Duration(seconds: 10));
      _playingHandles.remove(currentHandle);
      _log.fine('Sfx ${sfx.name} finished playing.');
    } catch (error, stacktrace) {
      _log.warning(
        'Error waiting for sfx ${sfx.name} to finish playing.',
        error,
        stacktrace,
      );
    }
  }

  Future<void> stop() async {
    await _initCompleter.future;

    if (_playingHandles.isEmpty) return;

    final tasks = <Future<void>>[];
    for (final handle in _playingHandles) {
      tasks.add(
        SoLoud.instance.stop(handle).then((_) {
          _log.info('Stopped sfx $handle');
          _playingHandles.remove(handle);
        }),
      );
    }
    await Future.wait(tasks);
  }

  Future<void> dispose() async {
    await _initCompleter.future;

    await stop();
    for (final audioSource in _audioSources.values.expand((e) => e)) {
      await SoLoud.instance.disposeSource(audioSource);
    }
    _audioSources.clear();
    _playingHandles.clear();
  }

  Future<Uint8List> _getAssetBytes(String assetPath) async {
    final ByteData assetByteData = await rootBundle.load(assetPath);
    return assetByteData.buffer.asUint8List(
      assetByteData.offsetInBytes,
      assetByteData.lengthInBytes,
    );
  }
}
