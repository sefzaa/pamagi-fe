import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:pamagi/features/home/logic/home_state.dart';

class FlashcardManualScreen extends StatefulWidget {
  final int maxLimit;
  const FlashcardManualScreen({super.key, required this.maxLimit});

  @override
  State<FlashcardManualScreen> createState() => _FlashcardManualScreenState();
}

class _FlashcardManualScreenState extends State<FlashcardManualScreen> {
  List<String> selectedWordIds = [];
  String searchQuery = '';

  void _submitSelection() {
    if (selectedWordIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih minimal 1 kata!')));
      return;
    }
    // Return word IDs ke Bottom Sheet
    Navigator.pop(context, selectedWordIds);
  }

  @override
  Widget build(BuildContext context) {
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
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is! HomeLoaded) return const Center(child: CircularProgressIndicator());

          final words = state.recentWords.where((w) {
            final rw = (w['russian_word'] ?? '').toString().toLowerCase();
            final tr = (w['translation'] ?? '').toString().toLowerCase();
            return rw.contains(searchQuery) || tr.contains(searchQuery);
          }).toList();

          return Column(
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
                child: ListView.separated(
                  itemCount: words.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey.shade200, height: 1),
                  itemBuilder: (context, index) {
                    final word = words[index];
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
          );
        },
      ),
    );
  }
}