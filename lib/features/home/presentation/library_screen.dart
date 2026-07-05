import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/data/home_repository.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:pamagi/features/home/presentation/add_word_sheet.dart';
import 'package:pamagi/features/home/presentation/library_filter_sheet.dart';
import 'package:pamagi/features/home/presentation/word_detail_screen.dart';
import 'package:pamagi/features/home/presentation/word_list_screen.dart';

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
              title: const Text('Detail Word'),
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
                context.read<HomeCubit>().fetchDashboardData(); // Update dashboard count
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

  @override
  Widget build(BuildContext context) {
    final repo = context.read<HomeCubit>().repository;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WordListScreen(
                  repository: context.read<HomeCubit>().repository,
                  title: 'Favorite Words',
                  isFavorite: true,
                ),
              ),
            );
          },
        ),
        title: const Text('PAMAGI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B), letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box, color: Color(0xFF00AA5B), size: 28),
            onPressed: () async {
              final bool? isAdded = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => BlocProvider.value(
                  value: context.read<HomeCubit>(),
                  child: AddWordSheet(repository: context.read<HomeCubit>().repository),
                ),
              );
              // Jika sukses nambah kata, refresh list library
              if (isAdded == true) _fetchWords(refresh: true);
            },
          ),
          IconButton(
              icon: const Icon(Icons.filter_list, color: Color(0xFF00AA5B), size: 28),
              onPressed: _openFilter
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF00AA5B),
        onRefresh: () => _fetchWords(refresh: true),
        child: words.isEmpty && !isLoading
            ? const Center(child: Text('Tidak ada kata ditemukan.'))
            : ListView.separated(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: words.length + (hasMore ? 1 : 0),
          separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200),
          itemBuilder: (context, index) {
            if (index == words.length) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: Color(0xFF00AA5B))));

            final word = words[index];
            final isFav = word['is_favorite'] == true;
            final isBook = word['is_bookmarked'] == true;

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
                              Text(word['russian_word'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                                child: Text(word['part_of_speech'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(word['translation'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
    );
  }
}