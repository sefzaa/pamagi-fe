import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/flashcards/logic/flashcard_cubit.dart';
import 'package:pamagi/features/flashcards/logic/flashcard_state.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';

class FlashcardQuizScreen extends StatefulWidget {
  final Map<String, dynamic>? config; // Untuk kuis baru
  final List<dynamic>? historyDetails; // Untuk resume/review
  final String? sessionId; // ID sesi jika resume/review
  final bool isReviewMode; // True jika status COMPLETED

  const FlashcardQuizScreen({
    super.key,
    this.config,
    this.historyDetails,
    this.sessionId,
    this.isReviewMode = false,
  });

  @override
  State<FlashcardQuizScreen> createState() => _FlashcardQuizScreenState();
}

class _FlashcardQuizScreenState extends State<FlashcardQuizScreen> {
  int currentIndex = 0;
  bool isFlipped = false;
  List<dynamic> flashcards = [];
  List<bool?> answers = [];

  @override
  void initState() {
    super.initState();
    // CEK MODE: Resume/Review atau Kuis Baru
    if (widget.historyDetails != null) {
      flashcards = widget.historyDetails!;
      answers = flashcards.map((e) => e['is_correct'] as bool?).toList();

      if (widget.isReviewMode) {
        currentIndex = 0; // Mulai dari awal untuk review
      } else {
        // Cari soal pertama yang belum dijawab (is_correct == null)
        currentIndex = answers.indexWhere((ans) => ans == null);
        if (currentIndex == -1) currentIndex = 0;
      }
    } else {
      // Kuis Baru: Panggil API Generate
      context.read<FlashcardCubit>().generateFlashcards(widget.config!);
    }
  }

  int get correctAnswers => answers.where((a) => a == true).length;

  void _answerCard(bool isCorrect) {
    setState(() {
      answers[currentIndex] = isCorrect;
      int nextUnanswered = answers.indexWhere((ans) => ans == null);

      if (nextUnanswered == -1) {
        _submitSession('COMPLETED');
      } else {
        currentIndex = nextUnanswered;
        isFlipped = false;
      }
    });
  }

  void _goPrevious() {
    if (currentIndex > 0) setState(() { currentIndex--; isFlipped = false; });
  }

  void _goNext() {
    // Di mode review bisa bebas next, di kuis harus dijawab dulu
    if (currentIndex < flashcards.length - 1 && (widget.isReviewMode || answers[currentIndex] != null)) {
      setState(() { currentIndex++; isFlipped = false; });
    }
  }

  void _submitSession(String status) {
    // Siapkan list details untuk dikirim ke backend
    List<Map<String, dynamic>> quizDetails = [];
    for (int i = 0; i < flashcards.length; i++) {
      if (answers[i] != null) {
        quizDetails.add({
          "word_id": flashcards[i]['word_id'] ?? flashcards[i]['id'],
          "is_correct": answers[i]
        });
      }
    }

    final payload = {
      "id": widget.sessionId ?? flashcards[0]['session_id'] ?? "new_session",
      "status": status,
      "total_words": flashcards.length,
      "correct_answers": correctAnswers,
      "incorrect_answers": answers.where((a) => a == false).length,
      "score": (correctAnswers / flashcards.length * 100).toInt(),
      "details": quizDetails
    };

    context.read<FlashcardCubit>().submitQuiz(payload);

    if (status == 'COMPLETED') {
      _showCompletionDialog();
    } else {
      // Jika IN_PROGRESS (Save & Quit)
      Navigator.pop(context, true);
      context.read<HomeCubit>().fetchDashboardData();
    }
  }

  void _showSaveConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Progress?'),
        content: const Text('Anda belum menyelesaikan kuis ini. Apakah Anda ingin menyimpannya untuk dilanjutkan nanti?'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(ctx); // Tutup dialog
                Navigator.pop(context); // Keluar tanpa save
              },
              child: const Text('Quit Without Saving', style: TextStyle(color: Colors.red))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AA5B)),
            onPressed: () {
              Navigator.pop(ctx);
              _submitSession('IN_PROGRESS');
            },
            child: const Text('Save & Quit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Session Complete!', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
        content: Text('You scored $correctAnswers out of ${flashcards.length}.', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AA5B)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
                context.read<HomeCubit>().fetchDashboardData();
              },
              child: const Text('Back to Menu', style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  void _showInfoSheet(Map<String, dynamic> word) {
    final examples = word['examples'] as List? ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Word Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
            const SizedBox(height: 16),
            Text(word['russian_word'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(word['translation'] ?? '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 24),
            const Text('Examples:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (examples.isEmpty) const Text('No examples available.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            ...examples.map((ex) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ex['russian_sentence'] ?? '', style: const TextStyle(fontSize: 15)),
                  Text('"${ex['translated_sentence'] ?? ''}"', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> word) {
    // Untuk review/resume, mode selalu default menampilkan rusia di depan agar rapi
    final mode = widget.config?['session_mode'] ?? 'RU';
    bool showRussianFront = mode != 'Translate';
    if (mode == 'Random') showRussianFront = (word['id'].hashCode + currentIndex) % 2 == 0;

    final frontText = showRussianFront ? word['russian_word'] : word['translation'];
    final backText = showRussianFront ? word['translation'] : word['russian_word'];
    final examples = word['examples'] as List? ?? [];

    return GestureDetector(
      onTap: () => setState(() => isFlipped = !isFlipped),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotateAnim,
            child: child,
            builder: (context, widget) {
              final isUnder = (ValueKey(isFlipped) != widget!.key);
              var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
              tilt = tilt * (isFlipped ? -1 : 1);
              final value = isUnder ? min(rotateAnim.value, pi / 2) : rotateAnim.value;
              return Transform(transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt), alignment: Alignment.center, child: widget);
            },
          );
        },
        child: Container(
          key: ValueKey(isFlipped),
          width: double.infinity,
          height: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                  child: Text(word['part_of_speech'] ?? 'Unknown', style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const Spacer(),
              Text(isFlipped ? backText : frontText, textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isFlipped ? Colors.black87 : const Color(0xFF00AA5B))),

              if (isFlipped && examples.isNotEmpty) ...[
                const SizedBox(height: 24),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 12),
                Text('"${examples[0]['russian_sentence'] ?? ''}"', textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Text(examples[0]['translated_sentence'] ?? '', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],

              const Spacer(),
              // LABEL BENAR/SALAH DI MODE REVIEW
              if (widget.isReviewMode)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                      color: answers[currentIndex] == true ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(
                    answers[currentIndex] == true ? 'Correctly Answered' : 'Incorrectly Answered',
                    style: TextStyle(color: answers[currentIndex] == true ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Text(isFlipped ? 'Tap to flip back' : 'Tap to flip', style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // POPSCOPE: Mencegat tombol back
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (widget.isReviewMode) {
          Navigator.pop(context); // Kalau review, langsung keluar saja
          return;
        }
        _showSaveConfirmation(); // Kalau kuis jalan, minta konfirmasi
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: SafeArea(
          child: BlocConsumer<FlashcardCubit, FlashcardState>(
            listener: (context, state) {
              if (state is FlashcardError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
              }
            },
            builder: (context, state) {
              if (state is FlashcardGenerated && flashcards.isEmpty) {
                flashcards = state.flashcards;
                answers = List.filled(flashcards.length, null);
              }

              if ((state is FlashcardLoading || state is FlashcardInitial) && flashcards.isEmpty) return const Center(child: CircularProgressIndicator(color: Color(0xFF00AA5B)));
              if (flashcards.isEmpty) return const Center(child: Text('No words found.'));

              final currentWord = flashcards[currentIndex];
              final progress = (currentIndex + 1) / flashcards.length;

              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              if (widget.isReviewMode) Navigator.pop(context);
                              else _showSaveConfirmation();
                            }
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(widget.isReviewMode ? 'Review Mode' : 'Session Progress', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(value: progress, backgroundColor: Colors.grey.shade300, color: const Color(0xFF00AA5B), minHeight: 6, borderRadius: BorderRadius.circular(10)),
                              const SizedBox(height: 4),
                              Text('${currentIndex + 1} / ${flashcards.length}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          color: currentIndex > 0 ? Colors.black87 : Colors.grey.shade300,
                          onPressed: currentIndex > 0 ? _goPrevious : null,
                        ),
                        Expanded(child: _buildCard(currentWord)),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios),
                          color: (currentIndex < flashcards.length - 1 && (widget.isReviewMode || answers[currentIndex] != null)) ? Colors.black87 : Colors.grey.shade300,
                          onPressed: (currentIndex < flashcards.length - 1 && (widget.isReviewMode || answers[currentIndex] != null)) ? _goNext : null,
                        ),
                      ],
                    ),

                    const Spacer(),
                    if (!widget.isReviewMode) ...[
                      Text('CURRENT SCORE', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('$correctAnswers', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                          Text(' / ${flashcards.length}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // TOMBOL BAWAH: Jika review, sembunyikan Wrong/Know
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (!widget.isReviewMode)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: () => _answerCard(false),
                              icon: const Icon(Icons.close, color: Colors.white),
                              label: const Text('Wrong', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        if (!widget.isReviewMode) const SizedBox(width: 12),

                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: BorderSide(color: Colors.grey.shade400), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                            onPressed: () => _showInfoSheet(currentWord),
                            icon: const Icon(Icons.lightbulb_outline, color: Colors.black87),
                            label: const Text('Info', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        if (!widget.isReviewMode) const SizedBox(width: 12),
                        if (!widget.isReviewMode)
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AA5B), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: () => _answerCard(true),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text('Know', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}