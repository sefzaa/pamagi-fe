import 'package:dio/dio.dart';
import 'package:pamagi/core/api_client.dart';
import 'package:pamagi/core/secure_storage_helper.dart';

class AuthRepository {
  final ApiClient apiClient;

  AuthRepository(this.apiClient);

  Future<void> login(String identifier, String password) async {
    try {
      final response = await apiClient.dio.post('/login', data: {
        "identifier": identifier,
        "password": password,
      });

      // Simpan token ke brankas
      final data = response.data;
      await SecureStorageHelper.saveTokens(
        data['access_token'],
        data['refresh_token'],
      );
    } on DioException catch (e) {
      // Menangkap error dari Backend Go
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Kredensial salah!');
      } else {
        throw Exception('Tidak ada koneksi ke server');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<void> register(Map<String, dynamic> requestBody) async {
    try {
      final response = await apiClient.dio.post('/register', data: requestBody);

      // Jika sukses, simpan token
      final data = response.data;
      await SecureStorageHelper.saveTokens(
        data['access_token'],
        data['refresh_token'],
      );
    } on DioException catch (e) {
      // 1. Tangkap error spesifik dari Backend
      if (e.response != null) {
        // Ini akan menampilkan pesan asli dari Go (misal: "username already exists")
        throw Exception(e.response?.data.toString() ?? 'Gagal daftar, cek inputanmu!');
      } else {
        // Ini kalau internet mati atau server mati
        throw Exception('Tidak ada koneksi ke server');
      }
    } catch (e) {
      // Error umum lainnya
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}