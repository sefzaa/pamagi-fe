import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:pamagi/features/home/logic/home_state.dart';
import 'package:pamagi/features/home/presentation/add_word_sheet.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Tidak pakai SafeArea lagi karena sudah di-handle Scaffold di MainLayout
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is HomeLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00AA5B)));
        } else if (state is HomeError) {
          return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.red)));
        } else if (state is HomeLoaded) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Lama SUDAH DIHAPUS DARI SINI

                // Card 1: Quick Start Review
                _buildQuickStartCard(),
                const SizedBox(height: 16),

                // Card 2: Vocabulary Mastery (Desain Baru)
                _buildVocabularyMasteryCard(state.totalWords, context),
                const SizedBox(height: 24),

                // Tabs Section: Categories & Word Types
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Categories', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                        const SizedBox(height: 8),
                        Container(height: 2, width: 80, color: const Color(0xFF00AA5B)),
                      ],
                    ),
                    const SizedBox(width: 24),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10),
                      child: Text('Word Types', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: state.categories.map((category) {
                      return _buildCategoryCard(Icons.folder_open, category['name'] ?? 'Unknown', 'Category', const Color(0xFF00AA5B));
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Tombol VIEW ALL di tengah bawah
                Center(
                  child: TextButton(
                      onPressed: () {},
                      child: const Text('VIEW ALL', style: TextStyle(color: Color(0xFF00AA5B), fontSize: 12, fontWeight: FontWeight.bold))
                  ),
                ),
                const SizedBox(height: 24),

                const Text('Recent Words', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                if (state.recentWords.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Belum ada kata nih, yuk klik icon + di atas!', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                  )
                else
                  ...state.recentWords.map((word) {
                    return _buildWordListTile(word['russian_word'] ?? 'Unknown', word['part_of_speech'] ?? 'N/A', word['translation'] ?? 'No translation');
                  }),
              ],
            ),
          );
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
                    builder: (_) {
                      return BlocProvider.value(
                        value: context.read<HomeCubit>(),
                        child: AddWordSheet(repository: context.read<HomeCubit>().repository),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.add, color: Color(0xFF00AA5B), size: 18),
                label: const Text('Add Word', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF00AA5B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
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

  Widget _buildWordListTile(String word, String type, String meaning) {
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
                    Text(word, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                      child: Text(type, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(meaning, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.volume_up_outlined, color: Colors.grey),
        ],
      ),
    );
  }
}