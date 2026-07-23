// import 'dart:io'; // Tambahkan import ini untuk HttpClient
// import 'package:dio/dio.dart';
// import 'package:dio/io.dart'; // Tambahkan import ini untuk IOHttpClientAdapter
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:pamagi/core/secure_storage_helper.dart';
//
// class ApiClient {
//   late Dio dio;
//
//   ApiClient() {
//     // Mengambil nilai dari .env
//     final baseUrl = dotenv.env['BASE_URL'] ?? 'https://pamagi.mydm.cloud';
//
//     dio = Dio(
//       BaseOptions(
//         baseUrl: baseUrl,
//         // Naikkan timeout menjadi 30 detik untuk menghindari gagal koneksi di awal
//         connectTimeout: const Duration(seconds: 30),
//         receiveTimeout: const Duration(seconds: 30),
//       ),
//     );
//
//     // Bypass validasi sertifikat SSL khusus untuk Android Emulator
//     dio.httpClientAdapter = IOHttpClientAdapter(
//       createHttpClient: () {
//         final client = HttpClient();
//         client.badCertificateCallback =
//             (X509Certificate cert, String host, int port) => true;
//         return client;
//       },
//     );
//
//     dio.interceptors.add(InterceptorsWrapper(
//       onRequest: (options, handler) async {
//         final token = await SecureStorageHelper.getAccessToken();
//         if (token != null) {
//           options.headers['Authorization'] = 'Bearer $token';
//         }
//         return handler.next(options);
//       },
//     ));
//   }
// }


import 'dart:io'; // Wajib ada untuk HttpClient
import 'package:dio/dio.dart';
import 'package:dio/io.dart'; // Wajib ada untuk IOHttpClientAdapter
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pamagi/core/secure_storage_helper.dart';

class ApiClient {
  late Dio dio;

  ApiClient() {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://pamagi.mydm.cloud';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30), // Waktu tunggu dilamain
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // KODE SAKTI UNTUK BYPASS HANDSHAKE EXCEPTION DI EMULATOR
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        // Memaksa aplikasi menerima apapun response SSL-nya (bypass)
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
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

    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
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
      onError: (DioException e, handler) async {
        // Tangkap pesan error dari backend Go (yang sudah diubah jadi bahasa Inggris)
        if (e.response?.data != null && e.response?.data is Map) {
          final errorMessage = e.response?.data['message'] ?? 'Something went wrong';
          e = e.copyWith(message: errorMessage);
        }

        // Logic Auto-Refresh Token
        if (e.response?.statusCode == 401) {
          final refreshToken = await SecureStorageHelper.getRefreshToken();
          if (refreshToken != null) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
              refreshDio.httpClientAdapter = dio.httpClientAdapter;

              final response = await refreshDio.post('/refresh', data: {
                'refresh_token': refreshToken,
              });

              final newAccess = response.data['access_token'];
              final newRefresh = response.data['refresh_token'];
              final status = response.data['user']['subscription_status'] ?? 'FREE';
              await SecureStorageHelper.saveAuthData(newAccess, newRefresh, status);

              e.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
              final retryResponse = await refreshDio.fetch(e.requestOptions);
              return handler.resolve(retryResponse);
            } catch (_) {
              await SecureStorageHelper.clearTokens();
            }
          }
        }
        return handler.next(e);
      },
    ));
  }
}