import 'package:pamagi/core/api_client.dart';

class HomeRepository {
  final ApiClient apiClient;

  HomeRepository(this.apiClient);

  Future<List<dynamic>> getCategories({bool forDropdown = false}) async {
    try {
      final response = await apiClient.dio.get(
        '/categories',
        queryParameters: forDropdown ? {'for_dropdown': true} : null,
      );
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Gagal memuat kategori: $e');
    }
  }

  Future<List<dynamic>> getWordTypes() async {
    try {
      final response = await apiClient.dio.get('/words/types');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Gagal memuat tipe kata: $e');
    }
  }

  Future<Map<String, dynamic>> getWords({
    String? categoryId,
    String? pos,
    bool? isFavorite,
    String? sortBy,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) queryParams['category_id'] = categoryId;
      if (pos != null) queryParams['part_of_speech'] = pos;
      if (isFavorite != null) queryParams['is_favorite'] = isFavorite;
      if (sortBy != null) queryParams['sort_by'] = sortBy;

      final response = await apiClient.dio.get('/words', queryParameters: queryParams);

      if (response.data is Map<String, dynamic> && response.data['data'] != null) {
        return {
          'data': response.data['data'] as List<dynamic>,
          'total_items': response.data['meta']?['total_items'] ?? 0,
        };
      }
      return {'data': [], 'total_items': 0};
    } catch (e) {
      throw Exception('Gagal memuat daftar kata: $e');
    }
  }

  Future<void> addCategory(String name, String icon) async {
    try {
      await apiClient.dio.post('/categories', data: {"name": name, "icon": icon});
    } catch (e) {
      throw Exception('Gagal menambah kategori: $e');
    }
  }

  Future<void> addWord(Map<String, dynamic> body) async {
    try {
      await apiClient.dio.post('/words', data: body);
    } catch (e) {
      throw Exception('Gagal menyimpan kata: $e');
    }
  }

  Future<void> toggleFavorite(String wordId) async {
    await apiClient.dio.patch('/words/$wordId/favorite');
  }

  Future<void> toggleBookmark(String wordId) async {
    await apiClient.dio.patch('/words/$wordId/bookmark');
  }
}