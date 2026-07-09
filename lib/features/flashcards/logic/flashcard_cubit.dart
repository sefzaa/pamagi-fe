import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/flashcards/data/flashcard_repository.dart';
import 'flashcard_state.dart';

class FlashcardCubit extends Cubit<FlashcardState> {
  final FlashcardRepository repository;

  FlashcardCubit(this.repository) : super(FlashcardInitial());

  Future<void> generateFlashcards(Map<String, dynamic> requestBody) async {
    emit(FlashcardLoading());
    try {
      final cards = await repository.generateFlashcards(requestBody);
      emit(FlashcardGenerated(cards));
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }

  Future<void> submitQuiz(Map<String, dynamic> requestBody) async {
    emit(FlashcardLoading());
    try {
      await repository.submitQuiz(requestBody);
      emit(FlashcardSubmitSuccess());
    } catch (e) {
      emit(FlashcardError(e.toString()));
    }
  }
}