enum Music {
  islandCove._(assetPath: 'assets/music/island_cove.mp3', volume: 0.4),
  crystalCave._(assetPath: 'assets/music/crystal_cave.mp3', volume: 0.5);

  final String assetPath;
  final double volume;

  const Music._({required this.assetPath, this.volume = 0.5});

  @override
  String toString() => 'Song<$name>';
}
