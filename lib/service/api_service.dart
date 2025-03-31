import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/manga.dart';

class ApiService {
  static const String MANGAS_URL =
      'https://657fc7106ae0629a3f53a003.mockapi.io/mangas';
  static const String CHAPTERS_URL =
      'https://657fc7106ae0629a3f53a003.mockapi.io/chapters';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Lấy danh sách truyện hot
  Future<List<Manga>> getHotMangas() async {
    try {
      final response = await http.get(
        Uri.parse(MANGAS_URL),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        // Lọc và lấy các truyện hot
        List<Manga> hotMangas = jsonData
            .map((comic) => Manga.fromJson(comic))
            .where((manga) => manga.isHot)
            .take(5)
            .toList();

        return hotMangas;
      }

      return [];
    } catch (e) {
      print('Error fetching hot mangas: $e');
      return [];
    }
  }

  // Lấy danh sách truyện có phân trang
  Future<Map<String, dynamic>> getMangas({int page = 1, int limit = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$MANGAS_URL?page=$page&limit=$limit'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final mangas = jsonData.map((comic) => Manga.fromJson(comic)).toList();

        return {
          'mangas': mangas,
          'hasMore': mangas.length == limit,
          'totalPages': 5, // Giả định
        };
      }

      return {
        'mangas': [],
        'hasMore': false,
        'totalPages': 1,
      };
    } catch (e) {
      print('Error fetching mangas: $e');
      return {
        'mangas': [],
        'hasMore': false,
        'totalPages': 1,
      };
    }
  }

  // Lấy chi tiết truyện
  Future<Manga> getMangaDetails(String slug) async {
    try {
      final mangaResponse = await http.get(
        Uri.parse('$MANGAS_URL?slug=$slug'),
      );

      if (mangaResponse.statusCode == 200) {
        final List<dynamic> mangaData = json.decode(mangaResponse.body);

        if (mangaData.isNotEmpty) {
          Manga manga = Manga.fromJson(mangaData[0]);

          // Lấy danh sách chapter
          final chaptersResponse = await http.get(
            Uri.parse('$CHAPTERS_URL?mangaId=${manga.id}'),
          );

          if (chaptersResponse.statusCode == 200) {
            final List<dynamic> chaptersData =
                json.decode(chaptersResponse.body);
            List<Chapter> chapters = chaptersData
                .map<Chapter>((chapterData) => Chapter(
                      id: chapterData['id'] ?? '',
                      title: chapterData['title'] ?? 'Chương',
                      number: int.tryParse(
                              chapterData['number']?.toString() ?? '0') ??
                          0,
                      uploadDate: chapterData['uploadDate'] != null
                          ? DateTime.parse(chapterData['uploadDate'])
                          : DateTime.now(),
                      images: chapterData['images'] != null
                          ? List<String>.from(chapterData['images'])
                          : [],
                    ))
                .toList();

            manga = manga.copyWith(chapters: chapters);
          }

          return manga;
        }
      }

      throw Exception('Không tìm thấy thông tin truyện');
    } catch (e) {
      print('Error fetching manga details: $e');
      throw Exception('Lỗi tải thông tin truyện');
    }
  }

  // Tìm kiếm truyện
  Future<List<Manga>> searchMangas(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$MANGAS_URL?search=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((comic) => Manga.fromJson(comic)).toList();
      }

      return [];
    } catch (e) {
      print('Error searching mangas: $e');
      return [];
    }
  }
}
