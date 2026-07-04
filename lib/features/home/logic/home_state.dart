abstract class HomeState {}

class HomeInitial extends HomeState {}
class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final List<dynamic> categories;
  final List<dynamic> recentWords;
  final int totalWords;

  HomeLoaded(this.categories, this.recentWords, this.totalWords);
}
class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}