import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/user.dart' as app_user;

class AuthApiService {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;
  AuthApiService._internal();

  // Đăng ký người dùng mới
  Future<Map<String, dynamic>> registerUser(app_user.User user) async {
    try {
      // Kiểm tra xem số điện thoại đã tồn tại chưa
      final querySnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: user.phone)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Số điện thoại đã được đăng ký',
        };
      }

      // Tạo người dùng với Firebase Authentication
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
      });

      return {
        'success': true,
        'message': 'Đăng ký thành công',
        'data': {
          'uid': userCredential.user!.uid,
          'email': userCredential.user!.email,
        },
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _handleAuthError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi đăng ký: $e',
      };
    }
  }

  // Đăng nhập người dùng
  Future<Map<String, dynamic>> loginUser(String phone, String password) async {
    try {
      // Tìm email người dùng từ số điện thoại
      final querySnapshot = await _firestore
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Số điện thoại chưa được đăng ký',
        };
      }

      final userData = querySnapshot.docs.first;
      final email = userData['email'];

      // Đăng nhập bằng Firebase Authentication
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lấy token
      final token = await userCredential.user!.getIdToken();

      return {
        'success': true,
        'message': 'Đăng nhập thành công',
        'token': token,
        'user': {
          'id': userCredential.user!.uid,
          'name': userData['username'],
          'phone': userData['phone'],
          'email': userData['email'],
        },
      };
    } on firebase_auth.FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': _handleAuthError(e),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi đăng nhập: $e',
      };
    }
  }

  // Xác thực token
  Future<Map<String, dynamic>> verifyToken(String token) async {
    try {
      // Kiểm tra tính hợp lệ của token
      final decodedToken = await _auth.currentUser?.getIdTokenResult();
      
      return {
        'success': decodedToken != null,
        'message': decodedToken != null 
          ? 'Token hợp lệ' 
          : 'Token không hợp lệ',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi xác thực token: $e',
      };
    }
  }

  // Cập nhật thông tin người dùng
  Future<Map<String, dynamic>> updateUserProfile(
      app_user.User user, String token) async {
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

      return {
        'success': true,
        'message': 'Cập nhật thông tin thành công',
        'data': user.toJson(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi cập nhật: $e',
      };
    }
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
        return 'Lỗi xác thực không xác định: ${e.message}';
    }
  }
}