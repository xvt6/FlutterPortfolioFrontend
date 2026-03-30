class Audio {
  final int id;
  final String displayName;
  final String description;
  final String fileIdentifier;
  final double? bpm;
  final String? musicKey;
  final List<String> vibes;

  Audio({
    required this.id,
    required this.displayName,
    required this.description,
    required this.fileIdentifier,
    this.bpm,
    this.musicKey,
    required this.vibes,
  });

  factory Audio.fromJson(Map<String, dynamic> json) {
    return Audio(
      id: json['id'],
      displayName: json['displayName'],
      description: json['description'],
      fileIdentifier: json['fileIdentifier'],
      bpm: (json['bpm'] as num?)?.toDouble(),
      musicKey: json['musicKey'],
      vibes: List<String>.from(json['vibes'] ?? []),
    );
  }
}
