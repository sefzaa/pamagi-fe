import 'package:pamagi/core/api_client.dart';

class HomeRepository {
  final ApiClient apiClient;

  HomeRepository(this.apiClient);

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await apiClient.dio.get('/users/me');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<List<dynamic>> getCategories({bool forDropdown = false}) async {
    try {
      final response = await apiClient.dio.get(
        '/categories',
        queryParameters: forDropdown ? {'for_dropdown': true} : null,
      );
      return (response.data as List<dynamic>?) ?? [];
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<List<dynamic>> getWordTypes() async {
    try {
      final response = await apiClient.dio.get('/words/types');
      return (response.data as List<dynamic>?) ?? [];
    } catch (e) {
      throw Exception('Failed to load word types: $e');
    }
  }

  Future<Map<String, dynamic>> getWords({
    String? categoryId,
    String? pos,
    bool? isFavorite,
    String? startDate,
    String? endDate,
    String? sortBy,
    String? search, // Tambahan parameter search
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};

      if (categoryId != null && categoryId.isNotEmpty) queryParams['category_id'] = categoryId;
      if (pos != null && pos.isNotEmpty) queryParams['part_of_speech'] = pos;
      if (isFavorite != null) queryParams['is_favorite'] = isFavorite;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (sortBy != null) queryParams['sort_by'] = sortBy;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await apiClient.dio.get('/words', queryParameters: queryParams);

      if (response.data is Map<String, dynamic> && response.data['data'] != null) {
        return {
          'data': response.data['data'] as List<dynamic>,
          'total_items': response.data['meta']?['total_items'] ?? 0,
        };
      }
      return {'data': [], 'total_items': 0};
    } catch (e) {
      throw Exception('Failed to load words: $e');
    }
  }

  Future<void> addCategory(String name, String icon) async {
    await apiClient.dio.post('/categories', data: {"name": name, "icon": icon});
  }

  Future<void> addWord(Map<String, dynamic> body) async {
    await apiClient.dio.post('/words', data: body);
  }

  Future<void> toggleFavorite(String wordId) async {
    await apiClient.dio.patch('/words/$wordId/favorite');
  }

  Future<void> deleteWord(String id) async {
    await apiClient.dio.delete('/words/$id');
  }

  Future<void> updateWord(String id, Map<String, dynamic> body) async {
    await apiClient.dio.put('/words/$id', data: body);
  }
}