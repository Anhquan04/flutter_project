import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_btl/bloc/common/constants.dart';
import '../model/user.dart';
import '../model/manga.dart';
import '../model/history.dart';

class StorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Singleton pattern
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Get the SharedPreferences instance
  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // User authentication methods
  Future<bool> saveToken(String? token) async {
    if (token == null) return false;
    final prefs = await _prefs;
    return await prefs.setString(Constants.tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString(Constants.tokenKey);
  }

  Future<bool> deleteToken() async {
    final prefs = await _prefs;
    return await prefs.remove(Constants.tokenKey);
  }

  // Add saveUser method to fix the error in auth_repository.dart
  Future<bool> saveUser(User user) async {
    try {
      final prefs = await _prefs;
      return await prefs.setString(
          Constants.userKey, jsonEncode(user.toJson()));
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  // Lưu và lấy lịch sử đọc truyện từ Firestore
  Future<List<ReadingHistory>> getReadingHistory() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      final docRef = _firestore
          .collection('user_data')
          .doc(currentUser.uid)
          .collection('reading_history');

      final snapshot =
          await docRef.orderBy('timestamp', descending: true).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ReadingHistory(
          manga: Manga.fromJson(data['manga']),
          timestamp: DateTime.parse(data['timestamp']),
          lastChapterId: data['lastChapterId'],
        );
      }).toList();
    } catch (e) {
      print('Error fetching reading history: $e');
      return [];
    }
  }

  Future<bool> addToReadingHistory(Manga manga, {String? chapterId}) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final docRef = _firestore
          .collection('user_data')
          .doc(currentUser.uid)
          .collection('reading_history')
          .doc(manga.id);

      await docRef.set({
        'manga': manga.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'lastChapterId': chapterId,
      });
      return true;
    } catch (e) {
      print('Error adding to reading history: $e');
      return false;
    }
  }

  Future<bool> clearReadingHistory() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final collectionRef = _firestore
          .collection('user_data')
          .doc(currentUser.uid)
          .collection('reading_history');

      final snapshot = await collectionRef.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      return true;
    } catch (e) {
      print('Error clearing reading history: $e');
      return false;
    }
  }

  // Lưu và lấy truyện yêu thích từ Firestore
  Future<List<String>> getFavoriteMangaIds() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      final docRef = _firestore.collection('user_data').doc(currentUser.uid);

      final doc = await docRef.get();
      if (!doc.exists || !doc.data()!.containsKey('favorite_mangas')) {
        return [];
      }

      return List<String>.from(doc.data()!['favorite_mangas'] ?? []);
    } catch (e) {
      print('Error fetching favorite mangas: $e');
      return [];
    }
  }

  Future<bool> toggleFavoriteManga(String mangaId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final docRef = _firestore.collection('user_data').doc(currentUser.uid);

      final doc = await docRef.get();
      List<String> favorites = [];

      if (doc.exists && doc.data()!.containsKey('favorite_mangas')) {
        favorites = List<String>.from(doc.data()!['favorite_mangas'] ?? []);
      }

      if (favorites.contains(mangaId)) {
        favorites.remove(mangaId);
      } else {
        favorites.add(mangaId);
      }

      await docRef.set({'favorite_mangas': favorites}, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error toggling favorite manga: $e');
      return false;
    }
  }

  // Lưu người dùng hiện tại
  Future<bool> saveCurrentUser(User user) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      await _firestore
          .collection('user_data')
          .doc(currentUser.uid)
          .set(user.toJson(), SetOptions(merge: true));

      final prefs = await _prefs;
      return await prefs.setString(
          Constants.userKey, jsonEncode(user.toJson()));
    } catch (e) {
      print('Error saving current user: $e');
      return false;
    }
  }

  // Lấy người dùng hiện tại
  Future<User?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final doc =
          await _firestore.collection('user_data').doc(currentUser.uid).get();

      if (!doc.exists) return null;

      return User.fromJson(doc.data()!);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  // Kiểm tra trạng thái đăng nhập
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  // Xóa toàn bộ dữ liệu
  Future<bool> clearAll() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(Constants.tokenKey);
      await prefs.remove(Constants.userKey);

      // Đăng xuất khỏi Firebase
      await _auth.signOut();

      return true;
    } catch (e) {
      print('Error clearing all data: $e');
      return false;
    }
  }
}
