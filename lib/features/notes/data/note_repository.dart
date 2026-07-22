// lib/features/notes/data/note_repository.dart
import 'package:pamagi/core/api_client.dart';

class NoteRepository {
  final ApiClient apiClient;

  NoteRepository(this.apiClient);

  Future<List<dynamic>> getNotes({String sortBy = 'updated_desc'}) async {
    try {
      final response = await apiClient.dio.get('/notes', queryParameters: {'sort': sortBy});
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to load notes: $e');
    }
  }

  Future<Map<String, dynamic>> getNoteDetail(String id) async {
    try {
      final response = await apiClient.dio.get('/notes/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load note detail: $e');
    }
  }

  Future<void> createNote(Map<String, dynamic> data) async {
    try {
      await apiClient.dio.post('/notes', data: data);
    } catch (e) {
      throw Exception('Failed to create note: $e');
    }
  }

  Future<void> updateNote(String id, Map<String, dynamic> data) async {
    try {
      await apiClient.dio.put('/notes/$id', data: data);
    } catch (e) {
      throw Exception('Failed to update note: $e');
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      await apiClient.dio.delete('/notes/$id');
    } catch (e) {
      throw Exception('Failed to delete note: $e');
    }
  }

  Future<void> togglePin(String id) async {
    await apiClient.dio.patch('/notes/$id/pin');
  }

  Future<void> toggleFavorite(String id) async {
    await apiClient.dio.patch('/notes/$id/favorite');
  }
}