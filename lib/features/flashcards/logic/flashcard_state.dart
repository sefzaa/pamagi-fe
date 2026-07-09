abstract class FlashcardState {}

class FlashcardInitial extends FlashcardState {}

class FlashcardLoading extends FlashcardState {}

class FlashcardGenerated extends FlashcardState {
  final List<dynamic> flashcards;
  FlashcardGenerated(this.flashcards);
}

class FlashcardSubmitSuccess extends FlashcardState {}

class FlashcardError extends FlashcardState {
  final String message;
  FlashcardError(this.message);
}