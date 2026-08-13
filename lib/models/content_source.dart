enum ContentSourceType {
  book,
  government,
  regulation,
  standard,
  guidance,
  trainingMaterial,
  other,
}

enum ContentSourceStatus {
  registered,
  analyzing,
  analyzed,
  archived,
}

class ContentSource {
  final String id;
  final String title;
  final String? author;
  final String? publisher;
  final String? edition;
  final int? publicationYear;
  final ContentSourceType type;
  final String? url;
  final String? localFileName;
  final String? mimeType;
  final int? fileSizeBytes;
  final ContentSourceStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ContentSource({
    required this.id,
    required this.title,
    this.author,
    this.publisher,
    this.edition,
    this.publicationYear,
    required this.type,
    this.url,
    this.localFileName,
    this.mimeType,
    this.fileSizeBytes,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  ContentSource copyWith({
    String? title,
    String? author,
    String? publisher,
    String? edition,
    int? publicationYear,
    ContentSourceType? type,
    String? url,
    String? localFileName,
    String? mimeType,
    int? fileSizeBytes,
    ContentSourceStatus? status,
    DateTime? updatedAt,
  }) {
    return ContentSource(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      publisher: publisher ?? this.publisher,
      edition: edition ?? this.edition,
      publicationYear: publicationYear ?? this.publicationYear,
      type: type ?? this.type,
      url: url ?? this.url,
      localFileName: localFileName ?? this.localFileName,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'publisher': publisher,
        'edition': edition,
        'publicationYear': publicationYear,
        'type': type.name,
        'url': url,
        'localFileName': localFileName,
        'mimeType': mimeType,
        'fileSizeBytes': fileSizeBytes,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ContentSource.fromJson(Map<String, dynamic> json) {
    return ContentSource(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      author: json['author']?.toString(),
      publisher: json['publisher']?.toString(),
      edition: json['edition']?.toString(),
      publicationYear: json['publicationYear'] is int
          ? json['publicationYear'] as int
          : int.tryParse(json['publicationYear']?.toString() ?? ''),
      type: ContentSourceType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => ContentSourceType.other,
      ),
      url: json['url']?.toString(),
      localFileName: json['localFileName']?.toString(),
      mimeType: json['mimeType']?.toString(),
      fileSizeBytes: json['fileSizeBytes'] is int
          ? json['fileSizeBytes'] as int
          : int.tryParse(json['fileSizeBytes']?.toString() ?? ''),
      status: ContentSourceStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => ContentSourceStatus.registered,
      ),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
