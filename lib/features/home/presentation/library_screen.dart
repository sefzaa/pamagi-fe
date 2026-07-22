import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:pamagi/features/home/presentation/add_word_sheet.dart';
import 'package:pamagi/features/home/presentation/library_filter_sheet.dart';
import 'package:pamagi/features/home/presentation/word_detail_screen.dart';
import 'package:country_picker/country_picker.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> words = [];
  Map<String, dynamic> activeFilters = {'sort_by': 'newest'};

  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchWords(refresh: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !isLoading && hasMore) {
        _fetchWords();
      }
    });
  }

  Future<void> _fetchWords({bool refresh = false}) async {
    if (isLoading) return;
    if (refresh) {
      currentPage = 1;
      hasMore = true;
      words.clear();
    }

    setState(() => isLoading = true);
    try {
      final repo = context.read<HomeCubit>().repository;
      final res = await repo.getWords(
        page: currentPage,
        limit: 20,
        categoryId: activeFilters['category_id'],
        pos: activeFilters['part_of_speech'],
        isFavorite: activeFilters['is_favorite'],
        isBookmarked: activeFilters['is_bookmarked'],
        sortBy: activeFilters['sort_by'],
      );

      final newWords = res['data'] as List;
      setState(() {
        if (newWords.length < 20) hasMore = false;
        words.addAll(newWords);
        currentPage++;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _openFilter() async {
    final repo = context.read<HomeCubit>().repository;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LibraryFilterSheet(repository: repo, currentFilters: activeFilters),
    );

    if (result != null) {
      setState(() => activeFilters = result);
      _fetchWords(refresh: true);
    }
  }

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
                if (isUpdated == true) _fetchWords(refresh: true);
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

  String _getFlagEmoji(String code) {
    try {
      // Fallback khusus untuk 'EN'
      // (Karena 'EN' adalah kode bahasa, sedangkan library membaca kode negara seperti 'GB' atau 'US')
      if (code.toUpperCase() == 'EN') return '🇬🇧';

      // Menggunakan library country_picker untuk otomatis mengambil bendera dari kode negara
      final country = CountryParser.parseCountryCode(code.toUpperCase());
      return country.flagEmoji;
    } catch (e) {
      // Jika kode kosong atau tidak dikenali, kembalikan bendera putih
      return '🌍';
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<HomeCubit>().repository;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 16.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: _openFilter,
                icon: const Icon(Icons.filter_list, color: Color(0xFF00AA5B), size: 18),
                label: const Text('Filter', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00AA5B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF00AA5B),
              onRefresh: () => _fetchWords(refresh: true),
              child: words.isEmpty && !isLoading
                  ? const Center(child: Text('No words found.', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: words.length + (hasMore ? 1 : 0),
                separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  if (index == words.length) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Color(0xFF00AA5B))));

                  final word = words[index];
                  final isFav = word['is_favorite'] == true;
                  final isBook = word['is_bookmarked'] == true;
                  final targets = word['targets'] as List? ?? [];

                  return InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WordDetailScreen(word: word))),
                    onLongPress: () => _showLongPressMenu(word, index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // 1. NATIVE WORD SEBAGAI JUDUL
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
                                // 2 & 3. TARGET LANGUAGES SEBAGAI SUBTITLE DENGAN BENDERA
                                targets.isEmpty
                                    ? const Text('No translation', style: TextStyle(color: Colors.grey, fontSize: 13))
                                    : Wrap(
                                  spacing: 12,
                                  children: targets.map((t) {
                                    final code = t['language_code'] ?? '';
                                    final flag = _getFlagEmoji(code); // Ambil emoji bendera
                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(flag, style: const TextStyle(fontSize: 14)), // Bendera
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
                                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
                                onPressed: () {
                                  setState(() => words[index]['is_favorite'] = !isFav);
                                  repo.toggleFavorite(word['id']);
                                },
                              ),
                              IconButton(
                                icon: Icon(isBook ? Icons.bookmark : Icons.bookmark_border, color: isBook ? const Color(0xFF00AA5B) : Colors.grey),
                                onPressed: () {
                                  setState(() => words[index]['is_bookmarked'] = !isBook);
                                  repo.toggleBookmark(word['id']);
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}