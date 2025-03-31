import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project_btl/bloc/common/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/manga.dart';
import '../model/history.dart';
import '../service/storage_service.dart';

class HistoryRepository {
  final StorageService _storageService = StorageService();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final HistoryRepository _instance = HistoryRepository._internal();
  factory HistoryRepository() => _instance;
  HistoryRepository._internal();

  // Get reading history
  Future<List<ReadingHistory>> getReadingHistory() async {
    return await _storageService.getReadingHistory();
  }

  // Add manga to reading history
  Future<bool> addToHistory(Manga manga, {String? chapterId}) async {
    return await _storageService.addToReadingHistory(manga, chapterId: chapterId);
  }

  // Clear reading history
  Future<bool> clearHistory() async {
    return await _storageService.clearReadingHistory();
  }

  // Xóa một truyện khỏi lịch sử đọc
  Future<bool> removeFromHistory(String mangaId) async {
    try {
      // Lấy danh sách lịch sử hiện tại
      final currentHistory = await _storageService.getReadingHistory();
      
      // Lọc ra các mục không phải truyện cần xóa
      final updatedHistory = currentHistory
          .where((history) => history.manga.id != mangaId)
          .toList();

      // Lưu lại danh sách lịch sử mới
      final historyStringList = 
          updatedHistory.map((h) => jsonEncode(h.toJson())).toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(Constants.readingHistoryKey, historyStringList);

      return true;
    } catch (e) {
      print('Error removing manga from history: $e');
      return false;
    }
  }
}