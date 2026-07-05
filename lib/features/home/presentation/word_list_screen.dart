import 'package:flutter/material.dart';
import 'package:pamagi/features/home/data/home_repository.dart';

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // FIX BG HITAM JADI PUTIH
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
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(word['russian_word'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                        const SizedBox(width: 8),
                        // FIX TAMBAH LABEL PART OF SPEECH
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                          child: Text(word['part_of_speech'] ?? 'N/A', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(word['translation'] ?? 'No translation', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
          );
        },
      ),
    );
  }
}