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

      final data = response.data;
      await SecureStorageHelper.saveAuthData(
        data['access_token'],
        data['refresh_token'],
        data['user']['subscription_status'] ?? 'FREE',
      );
    } on DioException catch (e) {
      String errorMessage = 'Invalid credentials!';
      if (e.response?.data != null && e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<void> register(Map<String, dynamic> requestBody) async {
    try {
      final response = await apiClient.dio.post('/register', data: requestBody);

      final data = response.data;
      await SecureStorageHelper.saveAuthData(
        data['access_token'],
        data['refresh_token'],
        data['user']['subscription_status'] ?? 'FREE',
      );
    } on DioException catch (e) {
      String errorMessage = 'Registration failed, please check your input!';
      if (e.response?.data != null && e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> requestBody) async {
    try {
      await apiClient.dio.put('/users/me', data: requestBody);
    } on DioException catch (e) {
      String errorMessage = 'Registration failed, please check your input!';
      if (e.response?.data != null && e.response?.data is Map) {
        errorMessage = e.response?.data['message'] ?? errorMessage;
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }
}