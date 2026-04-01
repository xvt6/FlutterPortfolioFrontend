const List<String> allowedMusicKeys = [
  'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'
];

List<String> mergeVibes(Set<String> existingVibes, String newVibesString) {
  final List<String> newVibes = newVibesString
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  return {...existingVibes, ...newVibes}.toList();
}

Map<String, dynamic> buildAudioUpdatePayload(
  String fileIdentifier, {
  String? description,
  double? bpm,
  String? musicKey,
  List<String>? vibes,
}) {
  return {
    'FileIdentifier': fileIdentifier,
    if (description != null) 'Description': description,
    if (bpm != null) 'BPM': bpm,
    if (musicKey != null) 'MusicKey': musicKey,
    if (vibes != null) 'Vibes': vibes,
  };
}
