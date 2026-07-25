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
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> words = [];
  Map<String, dynamic> activeFilters = {'sort_by': 'newest'};

  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;

  String searchQuery = ''; // Variabel penampung teks pencarian lokal

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

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
        sortBy: activeFilters['sort_by'],
        search: _searchController.text, // Parameter Search
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

  String _getFlagEmoji(String code) {
    try {
      if (code.toUpperCase() == 'EN') return '🇬🇧';
      return CountryParser.parseCountryCode(code.toUpperCase()).flagEmoji;
    } catch (e) {
      return '🌍';
    }
  }

  void _openFilter() async {
    final repo = context.read<HomeCubit>().repository;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
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
            ListTile(leading: const Icon(Icons.remove_red_eye, color: Colors.blue), title: const Text('Word Detail'), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => WordDetailScreen(word: word))); }),
            ListTile(leading: const Icon(Icons.edit, color: Colors.orange), title: const Text('Edit Word'), onTap: () async { Navigator.pop(ctx); final bool? isUpdated = await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => BlocProvider.value(value: context.read<HomeCubit>(), child: AddWordSheet(repository: context.read<HomeCubit>().repository, initialWord: word))); if (isUpdated == true) _fetchWords(refresh: true); }),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Delete Word', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(ctx); _confirmDelete(word['id'], index); }),
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
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async { Navigator.pop(ctx); try { await context.read<HomeCubit>().repository.deleteWord(wordId); setState(() => words.removeAt(index)); context.read<HomeCubit>().fetchDashboardData(); } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } }, child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<HomeCubit>().repository;

    final displayedWords = words.where((w) {
      if (searchQuery.isEmpty) return true;
      final nw = (w['native_word'] ?? '').toString().toLowerCase();
      final targets = w['targets'] as List? ?? [];
      final tr = targets.map((t) => (t['target_word'] ?? '').toString().toLowerCase()).join(' ');
      return nw.contains(searchQuery) || tr.contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val.toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search words...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => searchQuery = '');
                          }
                      )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00AA5B))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _openFilter,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00AA5B)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  child: const Icon(Icons.filter_list, color: Color(0xFF00AA5B), size: 20),
                ),
              ],
            ),
          ),

          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF00AA5B),
              onRefresh: () => _fetchWords(refresh: true),
              child: displayedWords.isEmpty && !isLoading
                  ? const Center(child: Text('No words found.', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: displayedWords.length + (hasMore ? 1 : 0),
                separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200),
                itemBuilder: (context, index) {
                  if (index == displayedWords.length) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Color(0xFF00AA5B))));

                  final word = displayedWords[index];
                  final isFav = word['is_favorite'] == true;
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
                                    Text(
                                        (word['native_word'] == null || word['native_word'].toString().trim().isEmpty)
                                            ? '-'
                                            : word['native_word'],
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))
                                    ),
                                    const SizedBox(width: 8),
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)), child: Text(word['part_of_speech'] ?? 'N/A', style: const TextStyle(fontSize: 10, color: Colors.grey))),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                targets.isEmpty
                                    ? const Text('No translation', style: TextStyle(color: Colors.grey, fontSize: 13))
                                    : Wrap(spacing: 12, children: targets.map((t) {
                                  final code = t['language_code'] ?? '';
                                  final flag = _getFlagEmoji(code);
                                  return Row(mainAxisSize: MainAxisSize.min, children: [Text(flag, style: const TextStyle(fontSize: 14)), const SizedBox(width: 4),
                                    Text(
                                        (t['target_word'] == null || t['target_word'].toString().trim().isEmpty)
                                            ? '-'
                                            : t['target_word'],
                                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13)
                                    )]);
                                }).toList()),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                                isFav ? Icons.bookmark : Icons.bookmark_border,
                                color: isFav ? const Color(0xFF00AA5B) : Colors.grey
                            ),
                            onPressed: () {
                              setState(() => words[index]['is_favorite'] = !isFav);
                              repo.toggleFavorite(word['id']); // <-- Tetap tembak endpoint Favorite
                            },
                          ),
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