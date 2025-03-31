class Manga {
  final String id;
  final String title;
  final String author;
  final String description;
  final String coverUrl;
  final List<String> categories;
  final int viewCount;
  bool isHot; // Loại bỏ từ khóa final
  final List<Chapter> chapters;
  final String slug;

  Manga({
    required this.id,
    required this.title,
    this.author = 'Chưa rõ',
    this.description = 'Chưa có mô tả',
    this.coverUrl = 'https://via.placeholder.com/150',
    this.categories = const [],
    this.viewCount = 0,
    bool? isHot, // Thay đổi kiểu khai báo
    this.chapters = const [],
    required this.slug,
  }) : isHot = isHot ?? false; // Sử dụng initializer list

  factory Manga.fromJson(Map<String, dynamic> json) {
    return Manga(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Tiêu đề không xác định',
      author: json['author'] ?? 'Chưa rõ',
      description: json['description'] ?? 'Chưa có mô tả',
      coverUrl: json['coverUrl'] ?? 'https://via.placeholder.com/150',
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : [],
      viewCount: json['viewCount'] ?? 0,
      isHot: json['isHot'] ?? false,
      slug: json['slug'] ?? '',
    );
  }

  // Thêm phương thức toJson
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'description': description,
      'coverUrl': coverUrl,
      'categories': categories,
      'viewCount': viewCount,
      'isHot': isHot,
      'slug': slug,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
    };
  }

  Manga copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? coverUrl,
    List<String>? categories,
    int? viewCount,
    bool? isHot,
    List<Chapter>? chapters,
    String? slug,
  }) {
    return Manga(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      categories: categories ?? this.categories,
      viewCount: viewCount ?? this.viewCount,
      isHot: isHot ?? this.isHot,
      chapters: chapters ?? this.chapters,
      slug: slug ?? this.slug,
    );
  }
}

class Chapter {
  final String id;
  final String title;
  final int number;
  final DateTime uploadDate;
  final List<String> images;

  Chapter({
    required this.id,
    required this.title,
    required this.number,
    required this.uploadDate,
    this.images = const [],
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      id: json['_id'] ?? '',
      title: json['name'] ?? 'Chương ${json['chapter']}',
      number: json['chapter'] ?? 0,
      uploadDate: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      images: json['chapter_image'] != null
          ? List<String>.from(json['chapter_image'].map((img) =>
              'https://sv1.otruyencdn.com/uploads/${json['chapter_path']}/${img['image_file']}'))
          : [],
    );
  }

  // Thêm phương thức toJson cho Chapter
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'number': number,
      'uploadDate': uploadDate.toIso8601String(),
      'images': images,
    };
  }
}
