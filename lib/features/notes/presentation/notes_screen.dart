import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/notes/logic/note_cubit.dart';
import 'package:pamagi/features/notes/logic/note_state.dart';
import 'package:pamagi/features/notes/presentation/note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<NoteCubit>().fetchNotes();
  }

  void _showNoteOptions(Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.push_pin, color: Colors.blue),
              title: Text(note['is_pinned'] == true ? 'Unpin Note' : 'Pin Note'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<NoteCubit>().repository.togglePin(note['id']).then((_) => context.read<NoteCubit>().fetchNotes());
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: Text(note['is_favorite'] == true ? 'Remove from Favorites' : 'Add to Favorites'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<NoteCubit>().repository.toggleFavorite(note['id']).then((_) => context.read<NoteCubit>().fetchNotes());
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Note', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                context.read<NoteCubit>().repository.deleteNote(note['id']).then((_) => context.read<NoteCubit>().fetchNotes());
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: BlocBuilder<NoteCubit, NoteState>(
        builder: (context, state) {
          if (state is NoteLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00AA5B)));
          } else if (state is NoteError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.red)));
          } else if (state is NoteLoaded) {
            final notes = state.notes;

            if (notes.isEmpty) {
              return const Center(child: Text('No notes yet. Tap + to create one!', style: TextStyle(color: Colors.grey)));
            }

            return RefreshIndicator(
              color: const Color(0xFF00AA5B),
              onRefresh: () => context.read<NoteCubit>().fetchNotes(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final isPinned = note['is_pinned'] == true;
                  final isFav = note['is_favorite'] == true;
                  final tags = note['tags'] as List? ?? [];

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isPinned ? const Color(0xFF00AA5B) : Colors.grey.shade300, width: isPinned ? 1.5 : 1),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final refresh = await Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditorScreen(noteId: note['id'])));
                        if (refresh == true) context.read<NoteCubit>().fetchNotes();
                      },
                      onLongPress: () => _showNoteOptions(note),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(note['title'] ?? 'Untitled', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                                Row(
                                  children: [
                                    if (isFav) const Icon(Icons.favorite, color: Colors.red, size: 18),
                                    if (isFav && isPinned) const SizedBox(width: 8),
                                    if (isPinned) const Icon(Icons.push_pin, color: Color(0xFF00AA5B), size: 18),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(note['preview'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 12),
                            if (tags.isNotEmpty)
                              Wrap(
                                spacing: 8,
                                children: tags.map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                                  child: Text('#$t', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                )).toList(),
                              )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00AA5B),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          final refresh = await Navigator.push(context, MaterialPageRoute(builder: (_) => const NoteEditorScreen()));
          if (refresh == true) {
            if (context.mounted) context.read<NoteCubit>().fetchNotes();
          }
        },
      ),
    );
  }
}