part of 'audio_controller_cubit.dart';

final class AudioControllerState extends Equatable {
  final bool musicOn;
  final bool soundsOn;

  const AudioControllerState({this.musicOn = false, this.soundsOn = false});

  AudioControllerState copyWith({bool? musicOn, bool? soundsOn}) {
    return AudioControllerState(
      musicOn: musicOn ?? this.musicOn,
      soundsOn: soundsOn ?? this.soundsOn,
    );
  }

  @override
  List<Object?> get props => [musicOn, soundsOn];
}
