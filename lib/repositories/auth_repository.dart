import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:project_btl/service/auth_api_service.dart';

import '../model/user.dart';
import '../service/storage_service.dart';

class AuthRepository {
  final AuthApiService apiService = AuthApiService();
  final StorageService _storageService = StorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Singleton pattern
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  // Đăng ký người dùng mới
  Future<Map<String, dynamic>> register(User user) async {
    try {
      // Kiểm tra xem số điện thoại đã được sử dụng chưa
      final phoneQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: user.phone)
          .get();

      if (phoneQuery.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Số điện thoại đã được đăng ký',
        };
      }

      // Đăng ký người dùng với Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );

      // Lưu thông tin người dùng vào Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': user.username,
        'phone': user.phone,
        'email': user.email,
        'dob': user.dob.toIso8601String(),
        'role': user.role,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Khởi tạo dữ liệu người dùng với danh sách truyện yêu thích trống
      await _firestore
          .collection('user_data')
          .doc(userCredential.user!.uid)
          .set({
        'favorite_mangas': [],
      });

      // Lưu vào local storage
      await _storageService.saveUser(user);

      return {
        'success': true,
        'message': 'Đăng ký thành công',
        'uid': userCredential.user!.uid,
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      return {
        'success': false,
        'message': _handleAuthError(e),
      };
    } catch (e) {
      print('Register Error: $e');
      return {
        'success': false,
        'message': 'Lỗi đăng ký: $e',
      };
    }
  }

  // Đăng nhập người dùng
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      // Tìm người dùng trong Firestore
      final userQuery = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Số điện thoại chưa được đăng ký',
        };

        // Nếu sử dụng email để đăng nhập
        // final authResult = await _auth.signInWithEmailAndPassword(
        //   email: userData['email'],
        //   password: password,
        // );
      }

      final userData = userQuery.docs.first.data();

      try {
        // Thử đăng nhập với Firebase Authentication
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: userData['email'],
          password: password,
        );

        // Tạo đối tượng User từ dữ liệu Firestore
        final user = User(
          username: userData['username'],
          phone: userData['phone'],
          email: userData['email'],
          password: password,
          dob: DateTime.parse(userData['dob']),
          role: userData['role'] ?? 'user',
        );

        // Lưu người dùng hiện tại và token
        await _storageService.saveCurrentUser(user);
        final token = await userCredential.user!.getIdToken();
        if (token != null) {
          await _storageService.saveToken(token);
        } else {
          // Xử lý trường hợp token null
          print('Token không hợp lệ');
        }

        // Đảm bảo dữ liệu truyện yêu thích được khởi tạo nếu chưa có
        final userDataRef =
            _firestore.collection('user_data').doc(userCredential.user!.uid);
        final userDataDoc = await userDataRef.get();

        if (!userDataDoc.exists) {
          // Nếu chưa có document user_data, tạo mới với danh sách truyện yêu thích trống
          await userDataRef.set({
            'favorite_mangas': [],
          });
        } else if (!userDataDoc.data()!.containsKey('favorite_mangas')) {
          // Nếu đã có document nhưng không có trường favorite_mangas, cập nhật thêm vào
          await userDataRef.update({
            'favorite_mangas': [],
          });
        }

        return {
          'success': true,
          'user': user,
          'message': 'Đăng nhập thành công',
        };
      } catch (authError) {
        // Nếu đăng nhập thất bại
        return {
          'success': false,
          'message': 'Mật khẩu không chính xác',
        };
      }
    } catch (e) {
      print('Login Error: $e');
      return {
        'success': false,
        'message': 'Đăng nhập thất bại: $e',
      };
    }
  }

  // Đăng xuất người dùng
  Future<bool> logout() async {
    try {
      await _auth.signOut();
      return await _storageService.clearAll();
    } catch (e) {
      print('Logout Error: $e');
      return false;
    }
  }

  // Cập nhật thông tin người dùng
  Future<Map<String, dynamic>> updateProfile(User user) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'message': 'Chưa đăng nhập',
        };
      }

      // Cập nhật thông tin trong Firestore
      await _firestore.collection('users').doc(currentUser.uid).update({
        'username': user.username,
        'email': user.email,
        'dob': user.dob.toIso8601String(),
      });

      // Cập nhật email nếu có thay đổi
      if (currentUser.email != user.email) {
        await currentUser.updateEmail(user.email);
      }

      // Lưu thông tin cục bộ
      await _storageService.saveUser(user);
      await _storageService.saveCurrentUser(user);

      return {
        'success': true,
        'message': 'Cập nhật thông tin thành công',
      };
    } catch (e) {
      print('Update Profile Error: $e');
      return {
        'success': false,
        'message': 'Lỗi cập nhật: $e',
      };
    }
  }

  // Kiểm tra trạng thái đăng nhập
  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }

  // Lấy thông tin người dùng hiện tại
  Future<User?> getCurrentUser() async {
    return await _storageService.getCurrentUser();
  }

  // Xác thực token
  Future<bool> verifyToken() async {
    try {
      final currentUser = _auth.currentUser;
      return currentUser != null;
    } catch (e) {
      print('Verify Token Error: $e');
      return false;
    }
  }

  // Lấy danh sách truyện yêu thích
  Future<List<String>> getFavoriteMangas() async {
    return await _storageService.getFavoriteMangaIds();
  }

  // Thêm hoặc xóa truyện yêu thích
  Future<bool> toggleFavoriteManga(String mangaId) async {
    return await _storageService.toggleFavoriteManga(mangaId);
  }

  // Kiểm tra xem một truyện có nằm trong danh sách yêu thích không
  Future<bool> isMangaFavorite(String mangaId) async {
    final favoriteIds = await _storageService.getFavoriteMangaIds();
    return favoriteIds.contains(mangaId);
  }

  // Xử lý các lỗi từ Firebase Authentication
  String _handleAuthError(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'user-not-found':
        return 'Người dùng không tồn tại';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa';
      default:
        return 'Lỗi xác thực: ${e.message}';
    }
  }
}
