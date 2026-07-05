import 'dart:io'; // Tambahkan import ini untuk HttpClient
import 'package:dio/dio.dart';
import 'package:dio/io.dart'; // Tambahkan import ini untuk IOHttpClientAdapter
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pamagi/core/secure_storage_helper.dart';

class ApiClient {
  late Dio dio;

  ApiClient() {
    // Mengambil nilai dari .env
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://pamagi.mydm.cloud';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // Naikkan timeout menjadi 30 detik untuk menghindari gagal koneksi di awal
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Bypass validasi sertifikat SSL khusus untuk Android Emulator
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
        return client;
      },
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