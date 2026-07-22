// lib/features/notes/logic/note_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/notes/data/note_repository.dart';
import 'note_state.dart';

class NoteCubit extends Cubit<NoteState> {
  final NoteRepository repository;

  NoteCubit(this.repository) : super(NoteInitial());

  Future<void> fetchNotes() async {
    emit(NoteLoading());
    try {
      final notes = await repository.getNotes();
      emit(NoteLoaded(notes));
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }
}