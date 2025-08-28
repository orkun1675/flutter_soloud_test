enum Sfx {
  meleeAttack._(assetPaths: ['assets/sfx/melee_sound.wav'], volume: 1.0);

  final List<String> assetPaths;
  final double volume;

  const Sfx._({required this.assetPaths, required this.volume});

  @override
  String toString() => 'Sfx<$name>';
}
