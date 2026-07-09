import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:pamagi/features/home/logic/home_state.dart';
import 'package:pamagi/features/home/presentation/add_word_sheet.dart';
import 'package:pamagi/features/home/presentation/word_list_screen.dart';
import 'package:pamagi/features/flashcards/presentation/flashcard_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // State untuk melacak tab mana yang sedang aktif
  bool isCategoryTab = true;

  IconData _getCategoryIcon(String? iconName) {
    final Map<String, IconData> iconMap = {
      'folder': Icons.folder, 'book': Icons.book, 'briefcase': Icons.business_center,
      'coffee': Icons.local_cafe, 'globe': Icons.public, 'heart': Icons.favorite,
      'music': Icons.music_note, 'shopping_cart': Icons.shopping_cart, 'camera': Icons.camera_alt,
    };
    return iconMap[iconName] ?? Icons.folder_open;
  }

  IconData _getPosIcon(String? posName) {
    final Map<String, IconData> posMap = {
      'NOUN': Icons.category, 'VERB': Icons.directions_run, 'ADJECTIVE': Icons.color_lens,
      'ADVERB': Icons.fast_forward, 'PRONOUN': Icons.person, 'PREPOSITION': Icons.place,
      'CONJUNCTION': Icons.link, 'INTERJECTION': Icons.feedback, 'IDIOM': Icons.forum,
    };
    return posMap[posName?.toUpperCase()] ?? Icons.text_snippet;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00AA5B)));
        } else if (state is HomeError) {
          return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)));
        } else if (state is HomeLoaded) {
          // --- MULAI DARI SINI ---
          return RefreshIndicator(
              color: const Color(0xFF00AA5B),
              onRefresh: () async {
                await context.read<HomeCubit>().fetchDashboardData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(), // Wajib ada biar bisa ditarik
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickStartCard(),
                const SizedBox(height: 16),
                _buildVocabularyMasteryCard(state.totalWords, context),
                const SizedBox(height: 24),

                // TABS: Categories & Word Types (Bisa Diklik)
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

                // LIST: Akan berubah tergantung tab mana yang dipencet
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: isCategoryTab
                        ? state.categories.map((category) {
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => WordListScreen(repository: context.read<HomeCubit>().repository, title: category['name'], categoryId: category['id']),
                        )),

                        child: _buildCategoryCard(_getCategoryIcon(category['icon']), category['name'] ?? 'Unknown', '${category['count'] ?? 0} words', const Color(0xFF00AA5B)),                      );
                    }).toList()
                        : state.wordTypes.map((type) {
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => WordListScreen(repository: context.read<HomeCubit>().repository, title: type['part_of_speech'], pos: type['part_of_speech']),
                        )),
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
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('Belum ada kata nih!', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))))
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

  Widget _buildQuickStartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.style, color: Color(0xFF00AA5B)),
          ),
          const SizedBox(height: 16),
          const Text('Quick Start Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Resume your spaced repetition session. You have 15 items waiting for review today.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          const Text('START SESSION  ➔', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
        ],
      ),
    );
  }

  Widget _buildFlashcardEntry(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke menu Flashcard di navbar (index 1)
        // Pastikan logic pindah tab navbar sudah ada, atau cukup buka layarnya:
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FlashcardScreen()));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.style, color: Color(0xFF00AA5B)),
            ),
            const SizedBox(height: 12),
            const Text('Quick Start Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Resume your spaced repetition session. Test your memory today!', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            const Text('START SESSION →', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildVocabularyMasteryCard(int totalWords, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('VOCABULARY MASTERY', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
              Icon(Icons.more_vert, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$totalWords', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                  Text('words learned', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => BlocProvider.value(value: context.read<HomeCubit>(), child: AddWordSheet(repository: context.read<HomeCubit>().repository)),
                  );
                },
                icon: const Icon(Icons.add, color: Color(0xFF00AA5B), size: 18),
                label: const Text('Add Word', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF00AA5B)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Consistency is key to fluency.', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(IconData icon, String title, String subtitle, Color iconColor) {
    return Container(
      width: 120, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, overflow: TextOverflow.ellipsis)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildWordListTile(Map<String, dynamic> word, BuildContext context) {
    final cubit = context.read<HomeCubit>();
    final isFav = word['is_favorite'] == true;
    final isBook = word['is_bookmarked'] == true;

    return Container(
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
                    Text(word['russian_word'] ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                    const SizedBox(width: 8),
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
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey, size: 22),
                onPressed: () => cubit.toggleWordFavorite(word['id'], isFav),
              ),
              IconButton(
                icon: Icon(isBook ? Icons.bookmark : Icons.bookmark_border, color: isBook ? const Color(0xFF00AA5B) : Colors.grey, size: 22),
                onPressed: () => cubit.toggleWordBookmark(word['id'], isBook),
              ),
            ],
          )
        ],
      ),
    );
  }
}