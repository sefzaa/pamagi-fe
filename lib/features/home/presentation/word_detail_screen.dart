import 'package:flutter/material.dart';

class WordDetailScreen extends StatelessWidget {
  final Map<String, dynamic> word;

  const WordDetailScreen({super.key, required this.word});

  @override
  Widget build(BuildContext context) {
    final examples = word['examples'] as List? ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Word Detail', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF00AA5B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF00AA5B).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(word['part_of_speech'] ?? 'N/A', style: const TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(word['russian_word'] ?? 'Unknown', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Translation', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(word['translation'] ?? 'No translation', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 32),

            if (examples.isNotEmpty) ...[
              const Text('Example Sentences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...examples.map((ex) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex['russian_sentence'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text('"${ex['translated_sentence'] ?? ''}"', style: const TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),
                  ],
                ),
              )),
            ]
          ],
        ),
      ),
    );
  }
}