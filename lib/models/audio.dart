class Audio {
  final int id;
  final String fileName;
  final String url;
  final DateTime uploadedAt;

  Audio({
    required this.id,
    required this.fileName,
    required this.url,
    required this.uploadedAt,
  });

  factory Audio.fromJson(Map<String, dynamic> json) {
    return Audio(
      id: json['id'],
      fileName: json['file_name'],
      url: json['url'],
      uploadedAt: DateTime.parse(json['uploaded_at']),
    );
  }
}
