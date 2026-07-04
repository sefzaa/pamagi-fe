import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Jangan lupa import ini
import 'package:pamagi/core/secure_storage_helper.dart';

class ApiClient {
  late Dio dio;

  ApiClient() {
    // Mengambil nilai dari .env
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://pamagi.mydm.cloud';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl, // Gunakan variabel dari .env
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorageHelper.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }
}