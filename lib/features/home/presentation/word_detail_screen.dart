import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:pamagi/features/home/presentation/add_word_sheet.dart';
import 'package:country_picker/country_picker.dart';


class WordDetailScreen extends StatefulWidget {
  final Map<String, dynamic> word;
  const WordDetailScreen({super.key, required this.word});

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  late Map<String, dynamic> currentWord;

  @override
  void initState() {
    super.initState();
    currentWord = Map<String, dynamic>.from(widget.word);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final DateTime d = DateTime.parse(dateStr.replaceFirst(' ', 'T'));
      final List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[d.month - 1]} ${d.day.toString().padLeft(2, '0')}, ${d.year}';
    } catch (e) { return dateStr; }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Word?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async { Navigator.pop(ctx); try { await context.read<HomeCubit>().repository.deleteWord(currentWord['id']); context.read<HomeCubit>().fetchDashboardData(); Navigator.pop(context); } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } }, child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  String _getFlagEmoji(String code) {
    try {
      if (code.toUpperCase() == 'EN') return '🇬🇧';
      return CountryParser.parseCountryCode(code.toUpperCase()).flagEmoji;
    } catch (e) {
      return '🌍';
    }
  }

  @override
  Widget build(BuildContext context) {
    final examples = currentWord['examples'] as List? ?? [];
    final categories = currentWord['categories'] as List? ?? [];
    final targets = currentWord['targets'] as List? ?? [];
    final isFav = currentWord['is_favorite'] == true;
    final repo = context.read<HomeCubit>().repository;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Word Detail', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, iconTheme: const IconThemeData(color: Color(0xFF00AA5B)), elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)), child: Text(currentWord['part_of_speech'] ?? 'N/A', style: const TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold, fontSize: 12))),
                      IconButton(
                        icon: Icon(
                            isFav ? Icons.bookmark : Icons.bookmark_border,
                            color: isFav ? const Color(0xFF00AA5B) : Colors.grey
                        ),
                        onPressed: () {
                          setState(() => currentWord['is_favorite'] = !isFav);
                          repo.toggleFavorite(currentWord['id']); // <-- Logic Favorite
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(currentWord['native_word'] ?? 'Unknown', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                  Divider(height: 32, color: Colors.grey.shade200),
                  const Text('Translations:', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...targets.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_getFlagEmoji(t['language_code'] ?? '')} [${t['language_code']}] ', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 16)),
                        Expanded(child: Text(t['target_word'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 16))),
                      ],
                    ),
                  )).toList(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8, runSpacing: 8,
                          children: categories.map((c) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(16)), child: Text(c['name'], style: const TextStyle(color: Color(0xFF00AA5B), fontSize: 11, fontWeight: FontWeight.bold)))).toList(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF00AA5B)),
                        onPressed: () async {
                          final bool? isUpdated = await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => BlocProvider.value(value: context.read<HomeCubit>(), child: AddWordSheet(repository: repo, initialWord: currentWord)));
                          if (isUpdated == true) Navigator.pop(context);
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (examples.isNotEmpty) ...[
              const Align(alignment: Alignment.centerLeft, child: Text('Example Sentences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              ...examples.map((ex) {
                final exTargets = ex['target_sentences'] as List? ?? [];
                return Container(
                  width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ex['native_sentence'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
                      const SizedBox(height: 8),
                      ...exTargets.map((et) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• ${_getFlagEmoji(et['language_code'] ?? '')} [${et['language_code']}] "${et['sentence']}"', style: TextStyle(fontSize: 14, color: Colors.green.shade800, fontStyle: FontStyle.italic)),
                      )).toList(),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 32),
            TextButton.icon(onPressed: _confirmDelete, icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text('DELETE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
            const SizedBox(height: 16),
            Text('Created: ${_formatDate(currentWord['created_at'])}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}