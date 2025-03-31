import 'manga.dart';

class ReadingHistory {
  final Manga manga;
  final DateTime timestamp;
  final String? lastChapterId;

  ReadingHistory({
    required this.manga,
    required this.timestamp,
    this.lastChapterId,
  });

  // Phương thức chuyển đổi từ JSON sang ReadingHistory
  factory ReadingHistory.fromJson(Map<String, dynamic> json) {
    return ReadingHistory(
      manga: Manga.fromJson(json['manga']),
      timestamp: DateTime.parse(json['timestamp']),
      lastChapterId: json['lastChapterId'],
    );
  }

  // Phương thức chuyển ReadingHistory sang JSON
  Map<String, dynamic> toJson() {
    return {
      'manga': manga.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'lastChapterId': lastChapterId,
    };
  }

  // Phương thức copyWith để dễ dàng tạo bản sao với các thay đổi
  ReadingHistory copyWith({
    Manga? manga,
    DateTime? timestamp,
    String? lastChapterId,
  }) {
    return ReadingHistory(
      manga: manga ?? this.manga,
      timestamp: timestamp ?? this.timestamp,
      lastChapterId: lastChapterId ?? this.lastChapterId,
    );
  }
}