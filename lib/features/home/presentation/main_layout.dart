import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/home/presentation/dashboard_screen.dart';
import 'package:pamagi/features/home/presentation/add_word_sheet.dart'; // Import form baru
import 'package:pamagi/features/home/logic/home_cubit.dart'; // Import ini untuk akses repository

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 2; // Mulai dari Dashboard

  final List<Widget> _screens = [
    const Center(child: Text('Library Screen')),
    const Center(child: Text('Flashcards Screen')),
    const DashboardScreen(), // Dashboard Screen kita
    const Center(child: Text('Bookmark Screen')),
    const Center(child: Text('Profile Screen')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // --- APPBAR GLOBAL UNTUK SEMUA HALAMAN ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.favorite, color: Color(0xFF00AA5B)), // Icon Love
          onPressed: () {},
        ),
        title: const Text('PAMAGI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B), letterSpacing: 1.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box, color: Color(0xFF00AA5B), size: 28), // Icon Plus (Tambah Kata)
            onPressed: () {
              // Membuka form Add Word dari bawah
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // Biar bisa tinggi
                backgroundColor: Colors.transparent,
                builder: (_) {
                  // Berikan provider dan repository yang sama ke bottom sheet
                  return BlocProvider.value(
                    value: context.read<HomeCubit>(),
                    child: AddWordSheet(repository: context.read<HomeCubit>().repository),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // ----------------------------------------
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF00AA5B), // Warna hijau baru
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.style_outlined), activeIcon: Icon(Icons.style), label: 'Flashcards'),
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), activeIcon: Icon(Icons.bookmark), label: 'Bookmark'), // Berubah jadi Bookmark
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}