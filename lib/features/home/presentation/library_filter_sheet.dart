import 'package:flutter/material.dart';
import 'package:pamagi/features/home/data/home_repository.dart';

class LibraryFilterSheet extends StatefulWidget {
  final HomeRepository repository;
  final Map<String, dynamic> currentFilters;

  const LibraryFilterSheet({super.key, required this.repository, required this.currentFilters});

  @override
  State<LibraryFilterSheet> createState() => _LibraryFilterSheetState();
}

class _LibraryFilterSheetState extends State<LibraryFilterSheet> {
  List<dynamic> categories = [];
  List<String> selectedCategories = [];
  List<String> selectedPos = [];
  String sortBy = 'newest';
  bool isFavorite = false;

  final List<String> posOptions = ['NOUN', 'VERB', 'ADJECTIVE', 'ADVERB', 'PRONOUN', 'PREPOSITION', 'CONJUNCTION', 'INTERJECTION', 'IDIOM', 'NONE'];
  final Map<String, String> sortOptions = {'newest': 'Newest First', 'oldest': 'Oldest First', 'a_z': 'A - Z', 'z_a': 'Z - A'};

  @override
  void initState() {
    super.initState();
    _loadInitialFilters();
    _fetchCategories();
  }

  void _loadInitialFilters() {
    sortBy = widget.currentFilters['sort_by'] ?? 'newest';
    isFavorite = widget.currentFilters['is_favorite'] ?? false;

    if (widget.currentFilters['category_id'] != null) selectedCategories = widget.currentFilters['category_id'].toString().split(',');
    if (widget.currentFilters['part_of_speech'] != null) selectedPos = widget.currentFilters['part_of_speech'].toString().split(',');
  }

  Future<void> _fetchCategories() async {
    final cats = await widget.repository.getCategories(forDropdown: true);
    if (mounted) setState(() => categories = cats);
  }

  void _applyFilters() {
    final filters = <String, dynamic>{'sort_by': sortBy};
    if (selectedCategories.isNotEmpty) filters['category_id'] = selectedCategories.join(',');
    if (selectedPos.isNotEmpty) filters['part_of_speech'] = selectedPos.join(',');
    if (isFavorite) filters['is_favorite'] = true;

    Navigator.pop(context, filters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter & Sort', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
              TextButton(onPressed: () => Navigator.pop(context, <String, dynamic>{}), child: const Text('Reset', style: TextStyle(color: Colors.red))),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Sort By'),
                  Wrap(
                    spacing: 8,
                    children: sortOptions.entries.map((e) => ChoiceChip(
                      label: Text(e.value, style: TextStyle(color: sortBy == e.key ? Colors.white : Colors.black87)),
                      selected: sortBy == e.key,
                      selectedColor: const Color(0xFF00AA5B),
                      onSelected: (val) => setState(() => sortBy = e.key),
                    )).toList(),
                  ),

                  _buildSectionTitle('Status'),
                  Wrap(
                    children: [
                      FilterChip(
                        label: const Text('Favorite'), selected: isFavorite,
                        selectedColor: const Color(0xFF00AA5B).withOpacity(0.2), checkmarkColor: const Color(0xFF00AA5B),
                        onSelected: (val) => setState(() => isFavorite = val),
                      ),
                    ],
                  ),

                  _buildSectionTitle('Categories'),
                  categories.isEmpty
                      ? const CircularProgressIndicator()
                      : Wrap(
                    spacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategories.contains(cat['id']);
                      return FilterChip(
                        label: Text(cat['name']),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00AA5B).withOpacity(0.2),
                        onSelected: (val) {
                          setState(() {
                            val ? selectedCategories.add(cat['id']) : selectedCategories.remove(cat['id']);
                          });
                        },
                      );
                    }).toList(),
                  ),

                  _buildSectionTitle('Word Types (Part of Speech)'),
                  Wrap(
                    spacing: 8,
                    children: posOptions.map((pos) {
                      final isSelected = selectedPos.contains(pos);
                      return FilterChip(
                        label: Text(pos),
                        selected: isSelected,
                        selectedColor: const Color(0xFF00AA5B).withOpacity(0.2),
                        onSelected: (val) {
                          setState(() {
                            val ? selectedPos.add(pos) : selectedPos.remove(pos);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AA5B), padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _applyFilters,
              child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}