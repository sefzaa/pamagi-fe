import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';

class FlashcardManualScreen extends StatefulWidget {
  final int maxLimit;
  const FlashcardManualScreen({super.key, required this.maxLimit});

  @override
  State<FlashcardManualScreen> createState() => _FlashcardManualScreenState();
}

class _FlashcardManualScreenState extends State<FlashcardManualScreen> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> words = [];
  List<String> selectedWordIds = [];
  String searchQuery = '';

  int currentPage = 1;
  bool isLoading = false;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchWords();

    // Setup Infinite Scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !isLoading && hasMore) {
        _fetchWords();
      }
    });
  }

  Future<void> _fetchWords() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    try {
      // Kita pakai repository dari HomeCubit untuk memanggil API GET /words
      final repo = context.read<HomeCubit>().repository;
      final res = await repo.getWords(page: currentPage, limit: 20);
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

  void _submitSelection() {
    if (selectedWordIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 kata!')));
      return;
    }
    Navigator.pop(context, selectedWordIds);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter pencarian lokal dari data yang sudah di-load
    final displayedWords = words.where((w) {
      final rw = (w['russian_word'] ?? '').toString().toLowerCase();
      final tr = (w['translation'] ?? '').toString().toLowerCase();
      return rw.contains(searchQuery) || tr.contains(searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('Select Words', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${selectedWordIds.length} / ${widget.maxLimit} selected', style: TextStyle(color: selectedWordIds.length == widget.maxLimit ? Colors.orange : Colors.grey, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF00AA5B)),
        elevation: 0,
        actions: [
          TextButton(onPressed: _submitSelection, child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))))
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search words...',
                prefixIcon: const Icon(Icons.search),
                filled: true, fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: words.isEmpty && isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF00AA5B)))
                : ListView.separated(
              controller: _scrollController,
              itemCount: displayedWords.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200, height: 1),
              itemBuilder: (context, index) {
                // Tampilkan loading indicator di paling bawah saat scroll
                if (index == displayedWords.length) {
                  return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator(color: Color(0xFF00AA5B))));
                }

                final word = displayedWords[index];
                final isSelected = selectedWordIds.contains(word['id']);

                return CheckboxListTile(
                  activeColor: const Color(0xFF00AA5B),
                  title: Text(word['russian_word'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(word['translation'] ?? ''),
                  value: isSelected,
                  onChanged: (bool? val) {
                    setState(() {
                      if (val == true) {
                        if (selectedWordIds.length >= widget.maxLimit) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Limit maksimal ${widget.maxLimit} kata!')));
                        } else {
                          selectedWordIds.add(word['id']);
                        }
                      } else {
                        selectedWordIds.remove(word['id']);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}