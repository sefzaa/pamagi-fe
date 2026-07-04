import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/data/home_repository.dart';
import 'package:pamagi/features/home/logic/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository repository;

  HomeCubit(this.repository) : super(HomeInitial());

  Future<void> fetchDashboardData() async {
    emit(HomeLoading());
    try {
      // Jalankan request berbarengan biar cepat
      final categoriesFuture = repository.getCategories();
      // Gunakan sort_by=newest (asumsi di BE kamu handle ini)
      final wordsFuture = repository.getWords(sortBy: 'newest');

      final categories = await categoriesFuture;
      final words = await wordsFuture;

      // Ambil max 5 kata terbaru untuk dashboard
      final recentWords = words.take(5).toList();
      // Hitung total kata dari length array
      final totalWords = words.length;

      emit(HomeLoaded(categories, recentWords, totalWords));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}