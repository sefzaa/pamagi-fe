import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:pamagi/features/home/logic/home_state.dart';
import 'package:pamagi/features/home/presentation/add_word_sheet.dart';
import 'package:pamagi/features/home/presentation/word_list_screen.dart';
import 'package:pamagi/features/flashcards/presentation/flashcard_screen.dart';
import 'package:pamagi/features/flashcards/logic/flashcard_cubit.dart';
import 'package:pamagi/features/flashcards/presentation/flashcard_setup_sheet.dart';
import 'package:pamagi/features/flashcards/presentation/flashcard_quiz_screen.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:country_picker/country_picker.dart';
import 'package:pamagi/features/home/presentation/word_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isCategoryTab = true;

  IconData _getCategoryIcon(String? iconName) {
    // Mapping icon sama dengan form add_word_sheet (LucideIcons)
    final Map<String, IconData> iconMap = {
      'folder': LucideIcons.folder, 'book': LucideIcons.book, 'briefcase': LucideIcons.briefcase, 'coffee': LucideIcons.coffee, 'globe': LucideIcons.globe, 'heart': LucideIcons.heart, 'music': LucideIcons.music, 'shopping_cart': LucideIcons.shopping_cart, 'camera': LucideIcons.camera, 'utensils': LucideIcons.utensils, 'car': LucideIcons.car, 'plane': LucideIcons.plane, 'activity': LucideIcons.activity, 'alarm_clock': LucideIcons.alarm_clock, 'anchor': LucideIcons.anchor, 'apple': LucideIcons.apple, 'archive': LucideIcons.archive, 'award': LucideIcons.award, 'backpack': LucideIcons.backpack, 'battery': LucideIcons.battery, 'bell': LucideIcons.bell, 'cloud': LucideIcons.cloud, 'cpu': LucideIcons.cpu, 'database': LucideIcons.database, 'droplet': LucideIcons.droplet, 'feather': LucideIcons.feather, 'flag': LucideIcons.flag, 'gift': LucideIcons.gift, 'glasses': LucideIcons.glasses, 'headphones': LucideIcons.headphones, 'key': LucideIcons.key, 'laptop': LucideIcons.laptop, 'map': LucideIcons.map, 'mic': LucideIcons.mic, 'moon': LucideIcons.moon, 'pen_tool': LucideIcons.pen_tool, 'printer': LucideIcons.printer, 'radio': LucideIcons.radio, 'scissors': LucideIcons.scissors, 'shield': LucideIcons.shield, 'smartphone': LucideIcons.smartphone, 'speaker': LucideIcons.speaker, 'star': LucideIcons.star, 'sun': LucideIcons.sun, 'target': LucideIcons.target, 'tv': LucideIcons.tv, 'umbrella': LucideIcons.umbrella, 'video': LucideIcons.video, 'watch': LucideIcons.watch, 'wifi': LucideIcons.wifi,
    };
    return iconMap[iconName?.toLowerCase()] ?? LucideIcons.folder;
  }

  IconData _getPosIcon(String? posName) {
    final Map<String, IconData> posMap = {'NOUN': Icons.category, 'VERB': Icons.directions_run, 'ADJECTIVE': Icons.color_lens, 'ADVERB': Icons.fast_forward, 'PRONOUN': Icons.person, 'PREPOSITION': Icons.place, 'CONJUNCTION': Icons.link, 'INTERJECTION': Icons.feedback, 'IDIOM': Icons.forum};
    return posMap[posName?.toUpperCase()] ?? Icons.text_snippet;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00AA5B)));
        if (state is HomeError) return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)));
        if (state is HomeLoaded) {
          final slogan = state.userProfile['slogan'] ?? 'Consistency is key to fluency.';

          return RefreshIndicator(
              color: const Color(0xFF00AA5B),
              onRefresh: () async => await context.read<HomeCubit>().fetchDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickStartCard(context),
                    const SizedBox(height: 16),
                    _buildVocabularyMasteryCard(state.totalWords, slogan, context),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => isCategoryTab = true),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isCategoryTab ? const Color(0xFF00AA5B) : Colors.grey)),
                              const SizedBox(height: 8),
                              Container(height: 2, width: 80, color: isCategoryTab ? const Color(0xFF00AA5B) : Colors.transparent),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () => setState(() => isCategoryTab = false),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text('Word Types', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: !isCategoryTab ? const Color(0xFF00AA5B) : Colors.grey)),
                              const SizedBox(height: 8),
                              Container(height: 2, width: 80, color: !isCategoryTab ? const Color(0xFF00AA5B) : Colors.transparent),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: isCategoryTab
                            ? state.categories.map((category) {
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WordListScreen(repository: context.read<HomeCubit>().repository, title: category['name'], categoryId: category['id']))),
                            child: _buildCategoryCard(_getCategoryIcon(category['icon']), category['name'] ?? 'Unknown', '${category['count'] ?? 0} words', const Color(0xFF00AA5B)),                      );
                        }).toList()
                            : state.wordTypes.map((type) {
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WordListScreen(repository: context.read<HomeCubit>().repository, title: type['part_of_speech'], pos: type['part_of_speech']))),
                            child: _buildCategoryCard(_getPosIcon(type['part_of_speech']), type['part_of_speech'] ?? 'Unknown', '${type['count']} words', const Color(0xFF00AA5B)),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(child: TextButton(onPressed: () {}, child: const Text('VIEW ALL', style: TextStyle(color: Color(0xFF00AA5B), fontSize: 12, fontWeight: FontWeight.bold)))),
                    const SizedBox(height: 24),
                    const Text('Recent Words', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (state.recentWords.isEmpty)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No words added yet!', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))))
                    else
                      ...state.recentWords.map((word) => _buildWordListTile(word, context)),
                  ],
                ),
              ));
        }
        return const Center(child: Text('Tidak ada data'));
      },
    );
  }

  Widget _buildQuickStartCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final config = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => BlocProvider.value(value: context.read<HomeCubit>(), child: const FlashcardSetupSheet()),
        );
        if (config != null && context.mounted) {
          final refresh = await Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(value: context.read<FlashcardCubit>(), child: FlashcardQuizScreen(config: config))));
          if (refresh == true && context.mounted) context.read<HomeCubit>().fetchDashboardData();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.style, color: Color(0xFF00AA5B))),
            const SizedBox(height: 16),
            const Text('Quick Start Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Resume your spaced repetition session. Test your memory today!', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            const Text('START SESSION  ➔', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
          ],
        ),
      ),
    );
  }

  Widget _buildVocabularyMasteryCard(int totalWords, String slogan, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [Text('VOCABULARY MASTERY', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)), Icon(Icons.more_vert, color: Colors.grey, size: 20)],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text('$totalWords', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))), Text('words learned', style: TextStyle(fontSize: 14, color: Colors.grey.shade600))],
              ),
              OutlinedButton.icon(
                onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => BlocProvider.value(value: context.read<HomeCubit>(), child: AddWordSheet(repository: context.read<HomeCubit>().repository))),
                icon: const Icon(Icons.add, color: Color(0xFF00AA5B), size: 18),
                label: const Text('Add Word', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF00AA5B)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(slogan, style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String title, String subtitle, Color iconColor) {
    return Container(
      width: 120, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [Icon(icon, color: iconColor, size: 30), const SizedBox(height: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, overflow: TextOverflow.ellipsis)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12))],
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

  void _showLongPressMenu(Map<String, dynamic> word) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.remove_red_eye, color: Colors.blue), title: const Text('Word Detail'), onTap: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => WordDetailScreen(word: word))); }),
            ListTile(leading: const Icon(Icons.edit, color: Colors.orange), title: const Text('Edit Word'), onTap: () async { Navigator.pop(ctx); final bool? isUpdated = await showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => BlocProvider.value(value: context.read<HomeCubit>(), child: AddWordSheet(repository: context.read<HomeCubit>().repository, initialWord: word))); if (isUpdated == true) context.read<HomeCubit>().fetchDashboardData(); }),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('Delete Word', style: TextStyle(color: Colors.red)), onTap: () { Navigator.pop(ctx); _confirmDelete(word['id']); }),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String wordId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Word?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () async { Navigator.pop(ctx); try { await context.read<HomeCubit>().repository.deleteWord(wordId); if (context.mounted) context.read<HomeCubit>().fetchDashboardData(); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); } }, child: const Text('Delete', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildWordListTile(Map<String, dynamic> word, BuildContext context) {
    final cubit = context.read<HomeCubit>();
    final isFav = word['is_favorite'] == true;
    final targets = word['targets'] as List? ?? [];

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WordDetailScreen(word: word))),
      onLongPress: () => _showLongPressMenu(word),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(word['native_word'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                      const SizedBox(width: 8),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)), child: Text(word['part_of_speech'] ?? 'N/A', style: const TextStyle(fontSize: 10, color: Colors.grey))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  targets.isEmpty
                      ? const Text('No translation', style: TextStyle(color: Colors.grey, fontSize: 13))
                      : Wrap(spacing: 12, children: targets.map((t) {
                    final code = t['language_code'] ?? '';
                    final flag = _getFlagEmoji(code);
                    return Row(mainAxisSize: MainAxisSize.min, children: [Text(flag, style: const TextStyle(fontSize: 14)), const SizedBox(width: 4), Text(t['target_word'] ?? '', style: TextStyle(color: Colors.grey.shade700, fontSize: 13))]);
                  }).toList(),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                  isFav ? Icons.bookmark : Icons.bookmark_border,
                  color: isFav ? const Color(0xFF00AA5B) : Colors.grey,
                  size: 22
              ),
              onPressed: () => cubit.toggleWordFavorite(word['id'], isFav), // <-- Tetap pakai logic Favorite
            ),
          ],
        ),
      ),
    );
  }
}