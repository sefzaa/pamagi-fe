import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_picker/country_picker.dart';
import 'package:pamagi/features/home/data/home_repository.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

// --- KELAS BANTUAN UNTUK FORM DINAMIS MULTI-BAHASA ---
class TargetInput {
  String langCode = 'EN';
  String flagEmoji = '🇬🇧';
  TextEditingController word = TextEditingController();
}

class ExampleTargetInput {
  String langCode = 'EN';
  String flagEmoji = '🇬🇧';
  TextEditingController sentence = TextEditingController();
}

class ExampleInput {
  TextEditingController nativeSentence = TextEditingController();
  List<ExampleTargetInput> targetSentences = [];
}
// -----------------------------------------------------

class AddWordSheet extends StatefulWidget {
  final HomeRepository repository;
  final Map<String, dynamic>? initialWord;
  const AddWordSheet({super.key, required this.repository, this.initialWord});

  @override
  State<AddWordSheet> createState() => _AddWordSheetState();
}

class _AddWordSheetState extends State<AddWordSheet> {
  bool _isSubmitted = false;
  final nativeWordController = TextEditingController();

  List<dynamic> categories = [];
  List<String> selectedCategoryIds = [];

  String? selectedPos;
  final List<String> posOptions = ['NOUN', 'VERB', 'ADJECTIVE', 'ADVERB', 'PRONOUN', 'PREPOSITION', 'CONJUNCTION', 'INTERJECTION', 'IDIOM'];

  List<TargetInput> targets = [];
  List<ExampleInput> examples = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    if (widget.initialWord != null) {
      final word = widget.initialWord!;
      nativeWordController.text = word['native_word'] ?? '';
      selectedPos = word['part_of_speech'];

      if (word['categories'] != null) {
        selectedCategoryIds = (word['categories'] as List).map((c) => c['id'].toString()).toList();
      }

      if (word['targets'] != null && (word['targets'] as List).isNotEmpty) {
        targets.clear();
        for (var t in word['targets']) {
          final tInput = TargetInput();
          tInput.langCode = t['language_code'] ?? 'EN';
          tInput.flagEmoji = _getFlagEmoji(tInput.langCode);
          tInput.word.text = t['target_word'] ?? '';
          targets.add(tInput);
        }
      }

      if (word['examples'] != null && (word['examples'] as List).isNotEmpty) {
        examples.clear();
        for (var ex in word['examples']) {
          final exampleInput = ExampleInput();
          exampleInput.nativeSentence.text = ex['native_sentence'] ?? '';

          if (ex['target_sentences'] != null) {
            for (var ts in ex['target_sentences']) {
              final tsInput = ExampleTargetInput();
              tsInput.langCode = ts['language_code'] ?? 'EN';
              tsInput.flagEmoji = _getFlagEmoji(tsInput.langCode);
              tsInput.sentence.text = ts['sentence'] ?? '';
              exampleInput.targetSentences.add(tsInput);
            }
          }
          examples.add(exampleInput);
        }
      }
    } else {
      targets.add(TargetInput());
      final defaultEx = ExampleInput();
      defaultEx.targetSentences.add(ExampleTargetInput());
      examples.add(defaultEx);
    }
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

  Future<void> _loadCategories() async {
    final cats = await widget.repository.getCategories(forDropdown: true);
    if (mounted) setState(() => categories = cats);
  }

  Future<void> _addNewCategory() async {
    final catController = TextEditingController();
    String selectedIcon = 'folder';

    final Map<String, IconData> iconList = {
      'folder': LucideIcons.folder, 'book': LucideIcons.book, 'briefcase': LucideIcons.briefcase,
      'activity': LucideIcons.activity, 'flag': LucideIcons.flag, 'heart': LucideIcons.heart,
    };

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Category', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: catController,
                  decoration: const InputDecoration(hintText: 'Category Name', focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00AA5B)))),
                ),
                const SizedBox(height: 16),
                const Align(alignment: Alignment.centerLeft, child: Text('Select Icon:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12, runSpacing: 12,
                  children: iconList.entries.map((entry) {
                    final isSelected = selectedIcon == entry.key;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = entry.key),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF00AA5B).withOpacity(0.2) : Colors.transparent,
                          border: Border.all(color: isSelected ? const Color(0xFF00AA5B) : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(entry.value, color: isSelected ? const Color(0xFF00AA5B) : Colors.grey),
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AA5B)),
              onPressed: () async {
                if (catController.text.isNotEmpty) {
                  Navigator.pop(context);
                  setState(() => isLoading = true);
                  await widget.repository.addCategory(catController.text, selectedIcon);
                  await _loadCategories();
                  setState(() => isLoading = false);
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategorySelection() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.55,
                padding: const EdgeInsets.all(24),
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
                                style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.black87 : Colors.black54)
                            ),
                            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : const Icon(Icons.circle_outlined, color: Colors.grey),
                            onTap: () {
                              setModalState(() {
                                isSelected ? selectedCategoryIds.remove(cat['id']) : selectedCategoryIds.add(cat['id']);
                              });
                              setState(() {});
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
                          Navigator.pop(context);
                          _addNewCategory();
                        },
                        icon: const Icon(Icons.add, color: Color(0xFF00AA5B)),
                        label: const Text('Create New Category', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: Color(0xFF00AA5B)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitWord() async {
    setState(() => _isSubmitted = true);

    if (nativeWordController.text.isEmpty || targets.isEmpty || targets.first.word.text.isEmpty || selectedPos == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in the required fields!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => isLoading = true);
    try {
      final body = {
        "native_word": nativeWordController.text,
        "part_of_speech": selectedPos,
        "category_ids": selectedCategoryIds,
        "targets": targets.where((t) => t.word.text.isNotEmpty).map((t) => {
          "language_code": t.langCode.isEmpty ? 'EN' : t.langCode,
          "target_word": t.word.text,
        }).toList(),
        "examples": examples.where((e) => e.nativeSentence.text.isNotEmpty).map((e) => {
          "native_sentence": e.nativeSentence.text,
          "target_sentences": e.targetSentences.where((ts) => ts.sentence.text.isNotEmpty).map((ts) => {
            "language_code": ts.langCode.isEmpty ? 'EN' : ts.langCode,
            "sentence": ts.sentence.text
          }).toList()
        }).toList(),
      };

      if (widget.initialWord != null) {
        await widget.repository.updateWord(widget.initialWord!['id'], body);
      } else {
        await widget.repository.addWord(body);
      }

      if (mounted) {
        context.read<HomeCubit>().fetchDashboardData();
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.initialWord != null ? 'Vocabulary updated successfully!' : 'Vocabulary added successfully!', style: const TextStyle(color: Colors.white)),
            backgroundColor: const Color(0xFF00AA5B)));
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
                Text(widget.initialWord != null ? 'Edit Vocabulary' : 'Add Vocabulary', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Native Word / Phrase (Bahasa Ibu)'),
                    _buildTextField(nativeWordController, 'e.g. повсеместный / ubiquitous', isRequired: true),

                    _buildLabel('Translations (Target Languages)'),
                    ...targets.asMap().entries.map((entry) {
                      int idx = entry.key;
                      TargetInput t = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showCountryPicker(
                                  context: context,
                                  showPhoneCode: false,
                                  onSelect: (Country country) {
                                    setState(() {
                                      t.langCode = country.countryCode;
                                      t.flagEmoji = country.flagEmoji;
                                    });
                                  },
                                );
                              },
                              child: Container(
                                width: 56,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(t.flagEmoji, style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: _buildTextField(t.word, 'Translation...', isRequired: idx == 0)),
                            if (targets.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () => setState(() => targets.removeAt(idx)),
                              )
                          ],
                        ),
                      );
                    }).toList(),

                    if (targets.length < 2)
                      TextButton.icon(
                        onPressed: () => setState(() => targets.add(TargetInput())),
                        icon: const Icon(Icons.add, color: Color(0xFF00AA5B), size: 16),
                        label: const Text('Add Target Language', style: TextStyle(color: Color(0xFF00AA5B), fontSize: 12)),
                      ),

                    _buildLabel('Category (Select 1 or more)'),
                    GestureDetector(
                      onTap: _showCategorySelection,
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 50),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Expanded(
                              child: selectedCategoryIds.isEmpty
                                  ? const Text('Tap to select categories...', style: TextStyle(color: Colors.grey))
                                  : Wrap(
                                spacing: 8, runSpacing: 8,
                                children: selectedCategoryIds.map((id) {
                                  final catName = categories.firstWhere((c) => c['id'] == id, orElse: () => {'name': 'Unknown'})['name'];
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: Colors.blue.shade50, border: Border.all(color: Colors.blue.shade200), borderRadius: BorderRadius.circular(16)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? const Color(0xFF00AA5B) : Colors.grey.shade300)),
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
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
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
                            _buildTextField(example.nativeSentence, 'Write a sentence in native language...', maxLines: 2),
                            const SizedBox(height: 8),

                            ...example.targetSentences.asMap().entries.map((tsEntry) {
                              int tsIdx = tsEntry.key;
                              ExampleTargetInput ts = tsEntry.value;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        showCountryPicker(
                                          context: context,
                                          showPhoneCode: false,
                                          onSelect: (Country country) {
                                            setState(() {
                                              ts.langCode = country.countryCode;
                                              ts.flagEmoji = country.flagEmoji;
                                            });
                                          },
                                        );
                                      },
                                      child: Container(
                                        width: 56,
                                        height: 48,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade400),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(ts.flagEmoji, style: const TextStyle(fontSize: 24)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: _buildTextField(ts.sentence, 'Translated sentence...')),
                                    if (example.targetSentences.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                        onPressed: () => setState(() => example.targetSentences.removeAt(tsIdx)),
                                      )
                                  ],
                                ),
                              );
                            }).toList(),

                            if (example.targetSentences.length < 2)
                              TextButton(
                                  onPressed: () => setState(() => example.targetSentences.add(ExampleTargetInput())),
                                  child: const Text('+ Add Translation', style: TextStyle(fontSize: 12))
                              )
                          ],
                        ),
                      );
                    }).toList(),

                    if (examples.length < 3)
                      TextButton.icon(
                        onPressed: () {
                          final newEx = ExampleInput();
                          newEx.targetSentences.add(ExampleTargetInput());
                          setState(() => examples.add(newEx));
                        },
                        icon: const Icon(Icons.add, color: Color(0xFF00AA5B)),
                        label: const Text('Add Example', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

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

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, bool isRequired = false}) {
    final hasError = _isSubmitted && isRequired && controller.text.isEmpty;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => setState((){}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hasError ? Colors.red.shade200 : Colors.grey, fontSize: 14),
        filled: hasError,
        fillColor: Colors.red.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey.shade400)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey.shade400)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00AA5B), width: 1.5)),
      ),
    );
  }
}