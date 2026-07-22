import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:country_picker/country_picker.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least 1 word!')));
      return;
    }
    Navigator.pop(context, selectedWordIds);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final displayedWords = words.where((w) {
      final nw = (w['native_word'] ?? '').toString().toLowerCase();
      final targets = w['targets'] as List? ?? [];
      final tr = targets.map((t) => t['target_word']).join(' ').toLowerCase();
      return nw.contains(searchQuery) || tr.contains(searchQuery);
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
                if (index == displayedWords.length) {
                  return const Padding(padding: EdgeInsets.all(16.0), child: Center(child: CircularProgressIndicator(color: Color(0xFF00AA5B))));
                }

                final word = displayedWords[index];
                final isSelected = selectedWordIds.contains(word['id']);

                final targets = word['targets'] as List? ?? [];
                final translationStr = targets.map((t) => '${_getFlagEmoji(t['language_code'] ?? '')} ${t['target_word']}').join('  •  ');

                return CheckboxListTile(
                  activeColor: const Color(0xFF00AA5B),
                  title: Text(word['native_word'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(translationStr),
                  value: isSelected,
                  onChanged: (bool? val) {
                    setState(() {
                      if (val == true) {
                        if (selectedWordIds.length >= widget.maxLimit) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Maximum limit is ${widget.maxLimit} words!')));
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