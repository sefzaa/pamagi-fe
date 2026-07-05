import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/data/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository repository;

  HomeCubit(this.repository) : super(HomeInitial());

  Future<void> fetchDashboardData() async {
    emit(HomeLoading());
    try {
      final categoriesFuture = repository.getCategories();
      final wordTypesFuture = repository.getWordTypes();
      final wordsFuture = repository.getWords(sortBy: 'newest');

      final categories = await categoriesFuture;
      final wordTypes = await wordTypesFuture;
      final wordsResponse = await wordsFuture;

      final recentWords = (wordsResponse['data'] as List).take(5).toList();
      final totalWords = wordsResponse['total_items'] as int;

      emit(HomeLoaded(categories, recentWords, wordTypes, totalWords));
    } catch (e, stacktrace) {
      print('=== ERROR DASHBOARD ===');
      print(e);
      print(stacktrace);
      emit(HomeError(e.toString()));
    }
  }

  // Optimistic Update untuk Dashboard
  void toggleWordFavorite(String wordId, bool currentStatus) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final updatedWords = currentState.recentWords.map((word) {
        // Fix Error Map Type Casting
        final wordMap = Map<String, dynamic>.from(word as Map);
        if (wordMap['id'] == wordId) {
          wordMap['is_favorite'] = !currentStatus;
        }
        return wordMap;
      }).toList();

      emit(HomeLoaded(currentState.categories, updatedWords, currentState.wordTypes, currentState.totalWords));
      repository.toggleFavorite(wordId).catchError((_) => fetchDashboardData());
    }
  }

  void toggleWordBookmark(String wordId, bool currentStatus) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final updatedWords = currentState.recentWords.map((word) {
        // Fix Error Map Type Casting
        final wordMap = Map<String, dynamic>.from(word as Map);
        if (wordMap['id'] == wordId) {
          wordMap['is_bookmarked'] = !currentStatus;
        }
        return wordMap;
      }).toList();

      emit(HomeLoaded(currentState.categories, updatedWords, currentState.wordTypes, currentState.totalWords));
      repository.toggleBookmark(wordId).catchError((_) => fetchDashboardData());
    }
  }
}