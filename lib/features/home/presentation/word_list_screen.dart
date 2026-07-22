import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_picker/country_picker.dart';
import 'package:pamagi/features/home/data/home_repository.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:pamagi/features/home/presentation/word_detail_screen.dart';
import 'package:pamagi/features/home/presentation/add_word_sheet.dart';

class WordListScreen extends StatefulWidget {
  final HomeRepository repository;
  final String title;
  final String? categoryId;
  final String? pos;
  final bool? isFavorite;

  const WordListScreen({super.key, required this.repository, required this.title, this.categoryId, this.pos, this.isFavorite});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  List<dynamic> words = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final res = await widget.repository.getWords(
        categoryId: widget.categoryId,
        pos: widget.pos,
        isFavorite: widget.isFavorite,
      );
      setState(() {
        words = res['data'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _optimisticToggleFav(int index, String id, bool current) {
    setState(() => words[index]['is_favorite'] = !current);
    widget.repository.toggleFavorite(id).catchError((_) => _fetchData());
  }

  void _optimisticToggleBook(int index, String id, bool current) {
    setState(() => words[index]['is_bookmarked'] = !current);
    widget.repository.toggleBookmark(id).catchError((_) => _fetchData());
  }

  String _getFlagEmoji(String code) {
    try {
      if (code.toUpperCase() == 'EN') return '🇬🇧';
      final country = CountryParser.parseCountryCode(code.toUpperCase());
      return country.flagEmoji;
    } catch (e) {
      return '🌍';
    }
  }

  // --- TAMBAHAN UNTUK LONG PRESS MENU ---
  void _showLongPressMenu(Map<String, dynamic> word, int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.remove_red_eye, color: Colors.blue),
              title: const Text('Word Detail'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => WordDetailScreen(word: word)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.orange),
              title: const Text('Edit Word'),
              onTap: () async {
                Navigator.pop(ctx);
                final bool? isUpdated = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => BlocProvider.value(
                    value: context.read<HomeCubit>(),
                    child: AddWordSheet(repository: context.read<HomeCubit>().repository, initialWord: word),
                  ),
                );
                if (isUpdated == true) _fetchData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Word', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(word['id'], index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String wordId, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Word?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<HomeCubit>().repository.deleteWord(wordId);
                setState(() => words.removeAt(index));
                context.read<HomeCubit>().fetchDashboardData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  // ----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF00AA5B)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00AA5B)))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: words.length,
        separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200),
        itemBuilder: (context, index) {
          final word = words[index];
          final targets = word['targets'] as List? ?? [];

          // Menggunakan InkWell untuk mendeteksi Long Press
          return InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WordDetailScreen(word: word))),
            onLongPress: () => _showLongPressMenu(word, index),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(word['native_word'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                              child: Text(word['part_of_speech'] ?? 'N/A', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        targets.isEmpty
                            ? const Text('No translation', style: TextStyle(color: Colors.grey, fontSize: 13))
                            : Wrap(
                          spacing: 12,
                          children: targets.map((t) {
                            final code = t['language_code'] ?? '';
                            final flag = _getFlagEmoji(code);
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(flag, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 4),
                                Text(t['target_word'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(word['is_favorite'] == true ? Icons.favorite : Icons.favorite_border, color: word['is_favorite'] == true ? Colors.red : Colors.grey),
                        onPressed: () => _optimisticToggleFav(index, word['id'], word['is_favorite'] ?? false),
                      ),
                      IconButton(
                        icon: Icon(word['is_bookmarked'] == true ? Icons.bookmark : Icons.bookmark_border, color: word['is_bookmarked'] == true ? const Color(0xFF00AA5B) : Colors.grey),
                        onPressed: () => _optimisticToggleBook(index, word['id'], word['is_bookmarked'] ?? false),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}