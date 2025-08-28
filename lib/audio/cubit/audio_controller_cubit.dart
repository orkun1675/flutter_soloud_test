import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_soloud_test/audio/data/audio_repository.dart';
import 'package:flutter_soloud_test/audio/model/sfx.dart';
import 'package:logging/logging.dart';

part 'audio_controller_state.dart';

class AudioControllerCubit extends Cubit<AudioControllerState> {
  static final _log = Logger('AudioControllerCubit');

  final AudioRepository _audioRepository;
  late final AppLifecycleListener _appLifecycleListener;

  bool _appInForeground = true;

  AudioControllerCubit({required AudioRepository audioRepository})
    : _audioRepository = audioRepository,
      super(const AudioControllerState()) {
    _appLifecycleListener = AppLifecycleListener(
      onResume: () => _handleAppStateChange(true),
      onInactive: () => _handleAppStateChange(false),
    );
  }

  Future<void> playSfx(Sfx sfx) async {
    await _audioRepository.playSfx(sfx);
  }

  Future<void> _handleAppStateChange(bool appInForeground) async {
    _log.info(
      'App state changed to ${appInForeground ? 'foreground' : 'background'}.',
    );
    _appInForeground = appInForeground;

    if (appInForeground) {
      await _audioRepository.setMusicOn(state.musicOn);
      await _audioRepository.setSoundsOn(state.soundsOn);
    } else {
      await _audioRepository.setMusicOn(false);
      await _audioRepository.setSoundsOn(false);
    }
  }

  Future<void> setMusicOn(bool musicOn) async {
    if (state.musicOn == musicOn) return;

    emit(state.copyWith(musicOn: musicOn));

    _log.fine(
      'Music on state changed to $musicOn while app is in '
      '${_appInForeground ? 'foreground' : 'background'}',
    );
    if (_appInForeground) {
      await _audioRepository.setMusicOn(musicOn);
    } else {
      await _audioRepository.setMusicOn(false);
    }
  }

  Future<void> setSoundsOn(bool soundsOn) async {
    if (state.soundsOn == soundsOn) return;

    emit(state.copyWith(soundsOn: soundsOn));

    _log.fine(
      'Sounds on state changed to $soundsOn while app is in '
      '${_appInForeground ? 'foreground' : 'background'}',
    );
    if (_appInForeground) {
      await _audioRepository.setSoundsOn(soundsOn);
    } else {
      await _audioRepository.setSoundsOn(false);
    }
  }

  @override
  Future<void> close() async {
    _appLifecycleListener.dispose();
    await _audioRepository.dispose();
    return super.close();
  }
}
