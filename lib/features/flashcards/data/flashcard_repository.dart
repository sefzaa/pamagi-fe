import 'package:pamagi/core/api_client.dart';

class FlashcardRepository {
  final ApiClient apiClient;

  FlashcardRepository(this.apiClient);

  Future<List<dynamic>> getHistory() async {
    try {
      final response = await apiClient.dio.get('/flashcards/history');
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to load flashcard history: $e');
    }
  }

  Future<List<dynamic>> generateFlashcards(Map<String, dynamic> requestBody) async {
    try {
      final response = await apiClient.dio.post('/flashcards/generate', data: requestBody);
      return response.data as List<dynamic>;
    } catch (e) {
      throw Exception('Failed to generate flashcards: $e');
    }
  }

  Future<void> submitQuiz(Map<String, dynamic> requestBody) async {
    try {
      await apiClient.dio.post('/flashcards/submit', data: requestBody);
    } catch (e) {
      throw Exception('Failed to submit quiz results: $e');
    }
  }
}