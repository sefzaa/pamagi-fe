import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/core/secure_storage_helper.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:pamagi/features/home/logic/home_state.dart';
import 'package:pamagi/features/flashcards/presentation/flashcard_manual_screen.dart';

class FlashcardSetupSheet extends StatefulWidget {
  const FlashcardSetupSheet({super.key});

  @override
  State<FlashcardSetupSheet> createState() => _FlashcardSetupSheetState();
}

class _FlashcardSetupSheetState extends State<FlashcardSetupSheet> {
  List<String> selectedCategories = [];
  List<String> selectedWordTypes = [];
  String selectedDateAdded = 'Today';
  String sessionMode = 'Native First';
  double numCards = 20; // Default slider

  bool isPremium = false;
  int maxLimit = 20;

  DateTime? customStartDate;
  DateTime? customEndDate;

  final List<String> posOptions = ['NOUN', 'VERB', 'ADJECTIVE', 'ADVERB', 'IDIOM'];
  final List<String> dateOptions = ['Today', 'Yesterday', 'This Week', 'This Month', 'Custom'];
  final List<String> modeOptions = ['Native First', 'Target First', 'Random'];

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
  }

  Future<void> _checkSubscriptionStatus() async {
    final status = await SecureStorageHelper.getSubscriptionStatus();
    setState(() {
      isPremium = status == 'PREMIUM';
      maxLimit = isPremium ? 75 : 20;
      // Kunci numCards agar tidak melebihi limit baru
      if (numCards > maxLimit) numCards = maxLimit.toDouble();
    });
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF00AA5B))),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        customStartDate = picked.start;
        customEndDate = picked.end;
        selectedDateAdded = 'Custom';
      });
    } else {
      // Jika batal pilih tanggal, kembalikan ke default
      if (selectedDateAdded == 'Custom' && customStartDate == null) {
        setState(() => selectedDateAdded = 'Today');
      }
    }
  }

  void _startSession() {
    // Siapkan parameter filter untuk dikirim ke backend
    final config = <String, dynamic>{
      'filter_type': 'all', // Default jika tidak ada filter spesifik
      'session_mode': sessionMode,
      "total_questions": numCards.toInt(),
    };

    if (selectedCategories.isNotEmpty) {
      config['filter_type'] = 'category';
      config['category_ids'] = selectedCategories; // Array
    }
    if (selectedWordTypes.isNotEmpty) {
      config['filter_type'] = 'part_of_speech';
      config['parts_of_speech'] = selectedWordTypes; // Array
    }

    // Logika Date Range
    final now = DateTime.now();
    if (selectedDateAdded == 'Today') {
      config['start_date'] = now.toIso8601String().split('T')[0];
      config['end_date'] = now.toIso8601String().split('T')[0];
    } else if (selectedDateAdded == 'Yesterday') {
      final yesterday = now.subtract(const Duration(days: 1));
      config['start_date'] = yesterday.toIso8601String().split('T')[0];
      config['end_date'] = yesterday.toIso8601String().split('T')[0];
    } else if (selectedDateAdded == 'This Week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      config['start_date'] = startOfWeek.toIso8601String().split('T')[0];
      config['end_date'] = now.toIso8601String().split('T')[0];
    } else if (selectedDateAdded == 'This Month') {
      final startOfMonth = DateTime(now.year, now.month, 1);
      config['start_date'] = startOfMonth.toIso8601String().split('T')[0];
      config['end_date'] = now.toIso8601String().split('T')[0];
    } else if (selectedDateAdded == 'Custom' && customStartDate != null && customEndDate != null) {
      config['start_date'] = customStartDate!.toIso8601String().split('T')[0];
      config['end_date'] = customEndDate!.toIso8601String().split('T')[0];
    }

    Navigator.pop(context, config);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
              const Spacer(),
              const Text('New Session', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
              const Spacer(flex: 2),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Configure your flashcard review settings.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('SELECT CATEGORIES'),
                  BlocBuilder<HomeCubit, HomeState>(
                    builder: (context, state) {
                      if (state is HomeLoaded) {
                        return Wrap(
                          spacing: 8, runSpacing: 8,
                          children: state.categories.map((cat) {
                            final isSelected = selectedCategories.contains(cat['id']);
                            return _buildChoiceChip(cat['name'], isSelected, () {
                              setState(() => isSelected ? selectedCategories.remove(cat['id']) : selectedCategories.add(cat['id']));
                            });
                          }).toList(),
                        );
                      }
                      return const CircularProgressIndicator();
                    },
                  ),
                  const Divider(height: 40),

                  _buildSectionTitle('WORD TYPES'),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: posOptions.map((pos) {
                      final isSelected = selectedWordTypes.contains(pos);
                      return _buildChoiceChip(pos, isSelected, () {
                        setState(() => isSelected ? selectedWordTypes.remove(pos) : selectedWordTypes.add(pos));
                      });
                    }).toList(),
                  ),
                  const Divider(height: 40),

                  _buildSectionTitle('DATE ADDED'),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: dateOptions.map((dateStr) {
                      final isSelected = selectedDateAdded == dateStr;
                      return _buildChoiceChip(
                          dateStr == 'Custom' && customStartDate != null ? 'Custom (Selected)' : dateStr,
                          isSelected,
                              () {
                            if (dateStr == 'Custom') {
                              _selectCustomDateRange();
                            } else {
                              setState(() => selectedDateAdded = dateStr);
                            }
                          },
                          icon: dateStr == 'Custom' ? Icons.calendar_today : null
                      );
                    }).toList(),
                  ),
                  const Divider(height: 40),

                  _buildSectionTitle('SESSION MODE'),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: modeOptions.map((mode) {
                      final isSelected = sessionMode == mode;
                      return _buildChoiceChip(mode, isSelected, () => setState(() => sessionMode = mode));
                    }).toList(),
                  ),
                  const Divider(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('NUMBER OF CARDS', padTop: false),
                      Text('${numCards.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF00AA5B), inactiveTrackColor: Colors.grey.shade200, thumbColor: const Color(0xFF00AA5B),
                    ),
                    child: Slider(
                      value: numCards,
                      min: 5,
                      max: maxLimit.toDouble(),
                      divisions: maxLimit == 20 ? 3 : 14, // Step per 5
                      onChanged: (val) => setState(() => numCards = val),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('5', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('$maxLimit', style: TextStyle(color: isPremium ? const Color(0xFF00AA5B) : Colors.grey, fontSize: 12, fontWeight: isPremium ? FontWeight.bold : FontWeight.normal)),
                    ],
                  ),
                  if (!isPremium)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Upgrade to Premium to review up to 75 cards at once.', style: TextStyle(color: Colors.orange, fontSize: 11, fontStyle: FontStyle.italic)),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

// UBAH BAGIAN BAWAH INI
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF00AA5B)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    // Panggil halaman Manual Select
                    final selectedIds = await Navigator.push<List<String>>(
                        context,
                        MaterialPageRoute(builder: (_) => BlocProvider.value(
                            value: context.read<HomeCubit>(),
                            child: FlashcardManualScreen(maxLimit: maxLimit)
                        ))
                    );

                    if (selectedIds != null && selectedIds.isNotEmpty) {
                      // Tutup bottom sheet & kirim konfigurasi "manual"
                      Navigator.pop(context, {
                        "filter_type": "manual",
                        "word_ids": selectedIds,
                        "total_questions": selectedIds.length,
                        "session_mode": sessionMode,
                      });
                    }
                  },
                  icon: const Icon(Icons.checklist, color: Color(0xFF00AA5B)),
                  label: const Text('Or Select Words Manually', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
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
                  onPressed: _startSession,
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  label: const Text('Start Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool padTop = true}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12, top: padTop ? 0 : 0),
      child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00AA5B) : Colors.white,
          border: Border.all(color: isSelected ? const Color(0xFF00AA5B) : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4), // Desain agak kotak seperti mockup
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.grey), const SizedBox(width: 6)],
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}