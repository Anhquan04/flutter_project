import '../model/manga.dart';
import '../service/api_service.dart';

class MangaRepository {
  final ApiService _apiService = ApiService();

  // Singleton pattern
  static final MangaRepository _instance = MangaRepository._internal();
  factory MangaRepository() => _instance;
  MangaRepository._internal();

  // Get hot mangas for homepage
  Future<List<Manga>> getHotMangas() async {
    try {
      final mangas = await _apiService.getHotMangas();
      // Đánh dấu các truyện này là hot
      for (var manga in mangas) {
        manga.isHot = true;
      }
      return mangas;
    } catch (e) {
      print("Error getting hot mangas: $e");
      // Trả về danh sách rỗng trong trường hợp lỗi
      return [];
    }
  }

  // Get manga list for browsing
  Future<Map<String, dynamic>> getMangas({int page = 1, int limit = 10}) async {
    try {
      return await _apiService.getMangas(page: page, limit: limit);
    } catch (e) {
      print("Error getting mangas: $e");
      // Trả về dữ liệu giả trong trường hợp lỗi
      return {
        'mangas': <Manga>[],
        'hasMore': false,
        'totalPages': 1,
      };
    }
  }

  // Get manga details
  Future<Manga> getMangaDetails(String slug) async {
    try {
      return await _apiService.getMangaDetails(slug);
    } catch (e) {
      print("Error getting manga details: $e");
      // Trả về một manga trống trong trường hợp lỗi
      throw Exception("Failed to load manga details");
    }
  }

  // Search mangas
  Future<List<Manga>> searchMangas(String query) async {
    if (query.isEmpty) {
      return [];
    }

    try {
      return await _apiService.searchMangas(query);
    } catch (e) {
      print("Error searching mangas: $e");
      // Trả về danh sách rỗng trong trường hợp lỗi
      return [];
    }
  }
}
