import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://202.155.95.224/bengkelku/api';

  static final Dio dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    contentType: 'application/json',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Accept': 'application/json'},
  ));

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  static Future<Options> authOptions() async {
    final token = await getToken();
    return Options(headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
  }
}
