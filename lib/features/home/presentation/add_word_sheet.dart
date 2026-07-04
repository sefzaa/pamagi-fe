import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/data/home_repository.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';

class ExampleInput {
  TextEditingController sentence = TextEditingController();
  TextEditingController translation = TextEditingController();
}

class AddWordSheet extends StatefulWidget {
  final HomeRepository repository;
  const AddWordSheet({super.key, required this.repository});

  @override
  State<AddWordSheet> createState() => _AddWordSheetState();
}

class _AddWordSheetState extends State<AddWordSheet> {
  final wordController = TextEditingController();
  final translationController = TextEditingController();

  List<dynamic> categories = [];
  List<String> selectedCategoryIds = [];

  String? selectedPos;
  final List<String> posOptions = ['NOUN', 'VERB', 'ADJECTIVE', 'ADVERB', 'PRONOUN', 'PREPOSITION', 'CONJUNCTION', 'INTERJECTION', 'IDIOM'];

  List<ExampleInput> examples = [ExampleInput()];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await widget.repository.getCategories();
    setState(() {
      categories = cats;
    });
  }

  Future<void> _addNewCategory() async {
    final catController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Category', style: TextStyle(color: Color(0xFF00AA5B), fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: catController,
          decoration: InputDecoration(
            hintText: 'e.g. Kata Kerja A1',
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00AA5B))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AA5B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            onPressed: () async {
              if (catController.text.isNotEmpty) {
                Navigator.pop(context);
                setState(() => isLoading = true);
                await widget.repository.addCategory(catController.text);
                await _loadCategories();
                setState(() => isLoading = false);
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- DESAIN MODAL KATEGORI YANG BARU & ELEGAN ---
  Future<void> _showCategorySelection() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.55, // 55% dari tinggi layar
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Categories', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.grey.shade200, height: 1),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = selectedCategoryIds.contains(cat['id']);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                              cat['name'],
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.black87 : Colors.black54
                              )
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.blue)
                              : const Icon(Icons.circle_outlined, color: Colors.grey),
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                selectedCategoryIds.remove(cat['id']);
                              } else {
                                selectedCategoryIds.add(cat['id']);
                              }
                            });
                            setState(() {}); // Update tampilan di belakang layar utama
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Tutup modal ini dulu
                        _addNewCategory();      // Baru buka input kategori baru
                      },
                      icon: const Icon(Icons.add, color: Color(0xFF00AA5B)),
                      label: const Text('Create New Category', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF00AA5B)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitWord() async {
    if (wordController.text.isEmpty || selectedPos == null || selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lengkapi Word, Category & Part of Speech bro!')));
      return;
    }

    setState(() => isLoading = true);
    try {
      final body = {
        "category_ids": selectedCategoryIds,
        "examples": examples
            .where((e) => e.sentence.text.isNotEmpty)
            .map((e) => {"russian_sentence": e.sentence.text, "translated_sentence": e.translation.text})
            .toList(),
        "part_of_speech": selectedPos,
        "russian_word": wordController.text,
        "translation": translationController.text
      };

      await widget.repository.addWord(body);

      if (mounted) {
        context.read<HomeCubit>().fetchDashboardData();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kosakata berhasil ditambahkan!', style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFF00AA5B)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding ini berguna agar form naik saat keyboard muncul, sehingga sticky button tidak tertutup keyboard
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                const Text('Add Vocabulary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),

            // --- AREA SCROLL UNTUK FORM SAJA ---
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Word / Phrase'),
                    _buildTextField(wordController, 'e.g. ubiquitous'),

                    _buildLabel('Translation / Meaning'),
                    _buildTextField(translationController, 'e.g. present, appearing...'),

                    _buildLabel('Category (Pilih 1 atau lebih)'),
                    GestureDetector(
                      onTap: _showCategorySelection,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 50),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: selectedCategoryIds.isEmpty
                                  ? const Text('Tap to select categories...', style: TextStyle(color: Colors.grey))
                                  : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selectedCategoryIds.map((id) {
                                  final catName = categories.firstWhere((c) => c['id'] == id, orElse: () => {'name': 'Unknown'})['name'];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      border: Border.all(color: Colors.blue.shade200),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(catName, style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
                                  );
                                }).toList(),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Part of Speech'),
                    Wrap(
                      spacing: 8,
                      children: posOptions.map((pos) {
                        final isSelected = selectedPos == pos;
                        return ChoiceChip(
                          label: Text(pos, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF00AA5B),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isSelected ? const Color(0xFF00AA5B) : Colors.grey.shade300),
                          ),
                          onSelected: (selected) => setState(() => selectedPos = pos),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    const Text('Examples', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                    const SizedBox(height: 8),

                    ...examples.asMap().entries.map((entry) {
                      int idx = entry.key;
                      ExampleInput example = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('EXAMPLE ${idx + 1}', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                if (examples.length > 1)
                                  InkWell(
                                    onTap: () => setState(() => examples.removeAt(idx)),
                                    child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  )
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(example.sentence, 'Write a sentence using the word...', maxLines: 2),
                            const SizedBox(height: 8),
                            _buildTextField(example.translation, 'Translation of the sentence...'),
                          ],
                        ),
                      );
                    }).toList(),

                    if (examples.length < 3)
                      TextButton.icon(
                        onPressed: () => setState(() => examples.add(ExampleInput())),
                        icon: const Icon(Icons.add, color: Color(0xFF00AA5B)),
                        label: const Text('Add Example', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
                      ),

                    // Beri sedikit ruang kosong di bagian bawah scroll
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // --- AREA STICKY BUTTON (MENGAMBANG DI BAWAH) ---
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AA5B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: isLoading ? null : _submitWord,
                icon: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.save, color: Colors.white),
                label: Text(isLoading ? 'Saving...' : 'Save Vocabulary', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00AA5B), width: 1.5)),
      ),
    );
  }
}