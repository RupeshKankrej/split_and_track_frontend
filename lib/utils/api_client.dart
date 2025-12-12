import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static Dio create(String baseUrl) {
    final dio = Dio(BaseOptions(baseUrl: baseUrl));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!options.path.contains('/auth')) {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('token');
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
      ),
    );

    return dio;
  }
}
