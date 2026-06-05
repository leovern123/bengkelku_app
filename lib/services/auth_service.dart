import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final res = await ApiService.dio.post('/login', data: {
      'email': email,
      'password': password,
    });
    return res.data;
  }

  static Future<void> logout() async {
    final options = await ApiService.authOptions();
    await ApiService.dio.post('/logout', options: options);
    await ApiService.clearToken();
  }

  static Future<UserModel?> getProfile() async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/me', options: options);
    if (res.data['success'] == true) {
      return UserModel.fromJson(res.data['data']);
    }
    return null;
  }
}
