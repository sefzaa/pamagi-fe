import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Wajib ada
import 'package:pamagi/core/api_client.dart';
import 'package:pamagi/features/auth/data/auth_repository.dart';
import 'package:pamagi/features/auth/logic/auth_cubit.dart';
import 'package:pamagi/features/auth/presentation/login_screen.dart';
import 'package:pamagi/features/auth/presentation/register_screen.dart';
import 'package:pamagi/features/home/presentation/main_layout.dart';
import 'package:pamagi/features/home/data/home_repository.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:pamagi/features/flashcards/data/flashcard_repository.dart';
import 'package:pamagi/features/flashcards/logic/flashcard_cubit.dart';

Future<void> main() async {
  // Wajib dipanggil sebelum runApp
  WidgetsFlutterBinding.ensureInitialized();
  // Load file .env yang ada di root folder
  await dotenv.load(fileName: ".env");

  // Inisialisasi dependensi
  final apiClient = ApiClient();
  final authRepository = AuthRepository(apiClient);
  final homeRepository = HomeRepository(apiClient);
  final flashcardRepository = FlashcardRepository(apiClient); // <--- Tambahkan ini

  runApp(MyApp(
      authRepository: authRepository,
      homeRepository: homeRepository,
      flashcardRepository: flashcardRepository // <--- Tambahkan ini

  ));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final HomeRepository homeRepository;
  final FlashcardRepository flashcardRepository;

  const MyApp({super.key,
    required this.authRepository,
    required this.homeRepository,
    required this.flashcardRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(authRepository),
        ),
        BlocProvider<HomeCubit>(
            create: (context) => HomeCubit(homeRepository)..fetchDashboardData()
        ),
        BlocProvider<FlashcardCubit>( // <--- Tambahkan blok ini
          create: (context) => FlashcardCubit(flashcardRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Pamagi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: const Color(0xFF2C2C2C),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => LoginScreen(),
          '/register': (context) => const RegisterScreen(), // Tambahkan ini
          '/home': (context) => const MainLayout(),         // Ubah ini ke MainLayout
        },
      ),
    );
  }
}