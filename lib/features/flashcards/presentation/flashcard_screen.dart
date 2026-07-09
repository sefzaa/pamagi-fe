import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/core/api_client.dart';
import 'package:pamagi/features/flashcards/data/flashcard_repository.dart';
import 'package:pamagi/features/flashcards/logic/flashcard_cubit.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:pamagi/features/flashcards/presentation/flashcard_setup_sheet.dart';
import 'package:pamagi/features/flashcards/presentation/flashcard_quiz_screen.dart';
import 'package:pamagi/features/home/presentation/word_list_screen.dart';
import 'package:pamagi/features/home/presentation/add_word_sheet.dart';

class FlashcardScreen extends StatefulWidget {
  final bool isPushed; // Penanda apakah layar ini dibuka dari Dashboard

  const FlashcardScreen({super.key, this.isPushed = false});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late FlashcardRepository _repository;
  List<dynamic> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _repository = FlashcardRepository(ApiClient());
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => isLoading = true);
    try {
      final data = await _repository.getHistory();
      if (mounted) {
        setState(() {
          history = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final d = DateTime.parse(dateStr.replaceFirst(' ', 'T'));
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (e) {
      return dateStr;
    }
  }

  // Bikin Header (AppBar) yang HANYA muncul kalau diakses dari Dashboard
  PreferredSizeWidget? _buildAppBar() {
    if (!widget.isPushed) return null; // Hilang jika ada di dalam Navbar

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF00AA5B)), // Warna panah back
      leading: IconButton(
        icon: const Icon(Icons.favorite, color: Colors.red),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WordListScreen(
                repository: context.read<HomeCubit>().repository,
                title: 'Favorite Words',
                isFavorite: true,
              ),
            ),
          );
        },
      ),
      title: const Text('PAMAGI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B), letterSpacing: 1.5)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.add_box, color: Color(0xFF00AA5B), size: 28),
          onPressed: () async {
            final bool? isAdded = await showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => BlocProvider.value(
                value: context.read<HomeCubit>(),
                child: AddWordSheet(repository: context.read<HomeCubit>().repository),
              ),
            );
            if (isAdded == true) {
              context.read<HomeCubit>().fetchDashboardData();
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(), // Panggil header cerdas di sini
      body: RefreshIndicator(
        color: const Color(0xFF00AA5B),
        onRefresh: _fetchHistory,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Banner Start New Session
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00AA5B),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: const Color(0xFF00AA5B).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ready for a challenge?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Test your memory and improve your vocabulary mastery.', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF00AA5B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () async {
                        final config = await showModalBottomSheet<Map<String, dynamic>>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => BlocProvider.value(
                            value: context.read<HomeCubit>(),
                            child: const FlashcardSetupSheet(),
                          ),
                        );
                        if (config != null && context.mounted) {
                          final refresh = await Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider.value(
                            value: context.read<FlashcardCubit>(),
                            child: FlashcardQuizScreen(config: config),
                          )));
                          if (refresh == true) _fetchHistory();
                        }
                      },
                      child: const Text('Start New Session', style: TextStyle(fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Text('Session History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),

              // List History
              isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Color(0xFF00AA5B))))
                  : history.isEmpty
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada riwayat kuis.', style: TextStyle(color: Colors.grey))))
                  : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final session = history[index];
                  final isCompleted = session['status'] == 'COMPLETED';

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCompleted ? const Color(0xFFE8F5E9) : Colors.orange.shade50,
                        child: Icon(isCompleted ? Icons.check_circle : Icons.pending_actions, color: isCompleted ? const Color(0xFF00AA5B) : Colors.orange),
                      ),
                      title: Text(_formatDate(session['created_at']), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(isCompleted
                          ? 'Score: ${session['correct_answers'] ?? 0} / ${session['total_words'] ?? 0}'
                          : 'In Progress: ${session['total_words'] ?? 0} words'),
                      trailing: isCompleted
                          ? const Text('Review', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold, fontSize: 12))
                          : const Text('Resume', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                      onTap: () async {
                        if (session['details'] == null || session['details'].isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Detail sesi tidak tersedia.')));
                          return;
                        }
                        final refresh = await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: context.read<FlashcardCubit>(),
                            child: FlashcardQuizScreen(
                              historyDetails: session['details'],
                              sessionId: session['id'],
                              isReviewMode: isCompleted,
                            ),
                          ),
                        ));
                        if (refresh == true) _fetchHistory();
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}