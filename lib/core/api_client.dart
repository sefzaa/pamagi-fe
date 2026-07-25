import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pamagi/core/secure_storage_helper.dart';

class ApiClient {
  late Dio dio;

  // SISTEM KUNCI (LOCK) UNTUK MENCEGAH HP HANG (ANR)
  static bool _isRefreshing = false;

  ApiClient() {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://pamagi.mydm.cloud';

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

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
        // Tangkap pesan error dari backend
        if (e.response?.data != null && e.response?.data is Map) {
          final errorMessage = e.response?.data['message'] ?? 'Something went wrong';
          e = e.copyWith(message: errorMessage);
        }

        // Logic Auto-Refresh Token
        if (e.response?.statusCode == 401) {

          // Jika token kedaluwarsa dan belum ada proses refresh yang berjalan
          if (!_isRefreshing) {
            _isRefreshing = true; // Kunci pintunya

            try {
              final refreshToken = await SecureStorageHelper.getRefreshToken();
              if (refreshToken != null) {
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

                _isRefreshing = false; // Buka kuncinya
                return handler.resolve(retryResponse);
              } else {
                await SecureStorageHelper.clearTokens();
              }
            } catch (_) {
              await SecureStorageHelper.clearTokens();
            } finally {
              _isRefreshing = false; // Pastikan kunci terbuka walau gagal
            }
          } else {
            // Jika pintu terkunci (sedang proses refresh oleh request lain),
            // biarkan error ini lewat agar UI menendang user ke Login.
            // Ini mencegah brankas HP (Keystore) hang gara-gara dibombardir request.
          }
        }
        return handler.next(e);
      },
    ));
  }
}



// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:dio/io.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:pamagi/core/secure_storage_helper.dart';
//
// class ApiClient {
//   late Dio dio;
//   static bool _isRefreshing = false;
//
//   ApiClient() {
//     final baseUrl = dotenv.env['BASE_URL'] ?? 'https://pamagi.mydm.cloud';
//
//     dio = Dio(
//       BaseOptions(
//         baseUrl: baseUrl,
//         connectTimeout: const Duration(seconds: 45), // Naikkan jadi 45 detik untuk mengantisipasi jaringan lambat
//         receiveTimeout: const Duration(seconds: 45),
//       ),
//     );
//
//     // PASTIKAN ADAPTER INI TERPASANG DENGAN BENAR
//     final adapter = IOHttpClientAdapter();
//     adapter.createHttpClient = () {
//       final client = HttpClient();
//       client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
//       return client;
//     };
//     dio.httpClientAdapter = adapter;
//
//     dio.interceptors.add(InterceptorsWrapper(
//       onRequest: (options, handler) async {
//         final token = await SecureStorageHelper.getAccessToken();
//         if (token != null) {
//           options.headers['Authorization'] = 'Bearer $token';
//         }
//         return handler.next(options);
//       },
//       onError: (DioException e, handler) async {
//         if (e.response?.data != null && e.response?.data is Map) {
//           final errorMessage = e.response?.data['message'] ?? 'Something went wrong';
//           e = e.copyWith(message: errorMessage);
//         }
//
//         if (e.response?.statusCode == 401) {
//           if (!_isRefreshing) {
//             _isRefreshing = true;
//             try {
//               final refreshToken = await SecureStorageHelper.getRefreshToken();
//               if (refreshToken != null) {
//                 final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
//                 refreshDio.httpClientAdapter = adapter; // Gunakan adapter yang sama
//
//                 final response = await refreshDio.post('/refresh', data: {
//                   'refresh_token': refreshToken,
//                 });
//
//                 final newAccess = response.data['access_token'];
//                 final newRefresh = response.data['refresh_token'];
//                 final status = response.data['user']['subscription_status'] ?? 'FREE';
//                 await SecureStorageHelper.saveAuthData(newAccess, newRefresh, status);
//
//                 e.requestOptions.headers['Authorization'] = 'Bearer $newAccess';
//                 final retryResponse = await refreshDio.fetch(e.requestOptions);
//
//                 _isRefreshing = false;
//                 return handler.resolve(retryResponse);
//               } else {
//                 await SecureStorageHelper.clearTokens();
//               }
//             } catch (_) {
//               await SecureStorageHelper.clearTokens();
//             } finally {
//               _isRefreshing = false;
//             }
//           }
//         }
//         return handler.next(e);
//       },
//     ));
//   }
// }