import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/data/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository repository;

  HomeCubit(this.repository) : super(HomeInitial());

  Future<void> fetchDashboardData() async {
    emit(HomeLoading());
    try {
      final profileFuture = repository.getUserProfile();
      final categoriesFuture = repository.getCategories();
      final wordTypesFuture = repository.getWordTypes();
      final wordsFuture = repository.getWords(sortBy: 'newest');

      final userProfile = await profileFuture;
      final categories = await categoriesFuture;
      final wordTypes = await wordTypesFuture;
      final wordsResponse = await wordsFuture;

      final recentWords = (wordsResponse['data'] as List).take(5).toList();
      final totalWords = wordsResponse['total_items'] as int;

      emit(HomeLoaded(categories, recentWords, wordTypes, totalWords, userProfile));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  void toggleWordFavorite(String wordId, bool currentStatus) {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      final updatedWords = currentState.recentWords.map((word) {
        final wordMap = Map<String, dynamic>.from(word as Map);
        if (wordMap['id'] == wordId) wordMap['is_favorite'] = !currentStatus;
        return wordMap;
      }).toList();

      emit(HomeLoaded(currentState.categories, updatedWords, currentState.wordTypes, currentState.totalWords, currentState.userProfile));
      repository.toggleFavorite(wordId).catchError((_) => fetchDashboardData());
    }
  }

}