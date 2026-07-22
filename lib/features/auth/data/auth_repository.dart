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
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Invalid credentials!');
      } else {
        throw Exception('Connection failed: ${e.message}');
      }
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
      if (e.response != null) {
        throw Exception(e.response?.data.toString() ?? 'Registration failed, please check your input!');
      } else {
        throw Exception('No connection to the server');
      }
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }
}