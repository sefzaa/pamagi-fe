import 'package:pamagi/core/api_client.dart';

class HomeRepository {
  final ApiClient apiClient;

  HomeRepository(this.apiClient);

  Future<List<dynamic>> getCategories() async {
    try {
      final response = await apiClient.dio.get('/categories');

      // /categories sudah langsung berupa List/Array dari backend
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Gagal memuat kategori: $e');
    }
  }

  Future<List<dynamic>> getWords({String? sortBy}) async {
    try {
      final response = await apiClient.dio.get(
        '/words',
        queryParameters: sortBy != null ? {'sort_by': sortBy} : null,
      );

      // /words dibungkus dalam object Pagination, jadi kita ekstrak key 'data'
      if (response.data is Map<String, dynamic> && response.data['data'] != null) {
        return response.data['data'] as List<dynamic>;
      }

      return []; // Return list kosong sebagai fallback
    } catch (e) {
      throw Exception('Gagal memuat daftar kata: $e');
    }
  }

  // Tambah Kategori Baru
  Future<void> addCategory(String name) async {
    try {
      await apiClient.dio.post('/categories', data: {
        "name": name,
        "icon": "folder", // Wajib dikirim berdasarkan Swagger API
      });
    } catch (e) {
      throw Exception('Gagal menambah kategori: $e');
    }
  }

  // Tambah Kata Baru
  Future<void> addWord(Map<String, dynamic> body) async {
    try {
      await apiClient.dio.post('/words', data: body);
    } catch (e) {
      throw Exception('Gagal menyimpan kata: $e');
    }
  }
}