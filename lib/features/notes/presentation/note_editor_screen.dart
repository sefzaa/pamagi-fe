import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fleather/fleather.dart';
import 'package:pamagi/features/notes/logic/note_cubit.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId; // Jika null berarti bikin baru, jika ada berarti edit

  const NoteEditorScreen({super.key, this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _tagsController = TextEditingController();

  // Menggunakan Controller dari Fleather
  FleatherController _fleatherController = FleatherController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.noteId != null) {
      _loadNoteDetail();
    }
  }

  Future<void> _loadNoteDetail() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<NoteCubit>().repository;
      final note = await repo.getNoteDetail(widget.noteId!);

      _titleController.text = note['title'] ?? '';

      final tags = note['tags'] as List? ?? [];
      _tagsController.text = tags.join(', ');

      // Membaca format Delta JSON ke dalam ParchmentDocument (Format standar Fleather)
      if (note['content'] != null && note['content'].toString().isNotEmpty) {
        final doc = ParchmentDocument.fromJson(jsonDecode(note['content']));
        _fleatherController = FleatherController(document: doc);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load note: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title cannot be empty!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = context.read<NoteCubit>().repository;

      // Mengubah isi rich text menjadi String JSON
      final contentJson = jsonEncode(_fleatherController.document.toDelta().toJson());

      final rawTags = _tagsController.text.split(',');
      final cleanTags = rawTags.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

      final payload = {
        "title": _titleController.text,
        "content": contentJson,
        "tags": cleanTags,
        "is_pinned": false,
        "is_favorite": false,
        "color": "#FFFFFF"
      };

      if (widget.noteId == null) {
        await repo.createNote(payload);
      } else {
        await repo.updateNote(widget.noteId!, payload);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved successfully!'), backgroundColor: Color(0xFF00AA5B)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save note: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF00AA5B)),
        title: Text(widget.noteId == null ? 'New Note' : 'Edit Note', style: const TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
        actions: [
          _isLoading
              ? const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF00AA5B), strokeWidth: 2)))
              : IconButton(icon: const Icon(Icons.check, size: 28), onPressed: _saveNote),
        ],
      ),
      body: _isLoading && widget.noteId != null
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00AA5B)))
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Note Title',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                TextField(
                  controller: _tagsController,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Tags (comma separated, e.g. grammar, tips)',
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.tag, size: 18, color: Colors.grey),
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade300),

          // Toolbar bawaan Fleather yang super ringan
          FleatherToolbar.basic(controller: _fleatherController),
          Divider(height: 1, color: Colors.grey.shade300),

          // Area Teks
          Expanded(
            child: FleatherEditor(
              padding: const EdgeInsets.all(16.0),
              controller: _fleatherController,
            ),
          ),
        ],
      ),
    );
  }
}