import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pamagi/core/api_client.dart';
import 'package:pamagi/core/secure_storage_helper.dart'; // Import ini untuk Auto-Login
import 'package:pamagi/features/auth/data/auth_repository.dart';
import 'package:pamagi/features/auth/logic/auth_cubit.dart';
import 'package:pamagi/features/auth/presentation/login_screen.dart';
import 'package:pamagi/features/auth/presentation/register_screen.dart';
import 'package:pamagi/features/home/presentation/main_layout.dart';
import 'package:pamagi/features/home/data/home_repository.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';
import 'package:pamagi/features/flashcards/data/flashcard_repository.dart';
import 'package:pamagi/features/flashcards/logic/flashcard_cubit.dart';
import 'package:pamagi/features/notes/data/note_repository.dart';
import 'package:pamagi/features/notes/logic/note_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // BUNGKUS PENGECEKAN TOKEN DENGAN TRY-CATCH
  String initialRoute = '/';
  try {
    final token = await SecureStorageHelper.getAccessToken();
    if (token != null) {
      initialRoute = '/home';
    }
  } catch (e) {
    // Jika terjadi error sinkronisasi Keystore (biasanya karena reinstall), paksa ke halaman login
    initialRoute = '/';
  }

  final apiClient = ApiClient();
  final authRepository = AuthRepository(apiClient);
  final homeRepository = HomeRepository(apiClient);
  final flashcardRepository = FlashcardRepository(apiClient);
  final noteRepository = NoteRepository(apiClient);

  runApp(MyApp(
    authRepository: authRepository,
    homeRepository: homeRepository,
    flashcardRepository: flashcardRepository,
    noteRepository: noteRepository,
    initialRoute: initialRoute,
  ));
}

class MyApp extends StatelessWidget {
  final AuthRepository authRepository;
  final HomeRepository homeRepository;
  final FlashcardRepository flashcardRepository;
  final NoteRepository noteRepository;
  final String initialRoute; // Menerima route awal

  const MyApp({
    super.key,
    required this.authRepository,
    required this.homeRepository,
    required this.flashcardRepository,
    required this.noteRepository,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(create: (context) => AuthCubit(authRepository)),
        BlocProvider<HomeCubit>(create: (context) => HomeCubit(homeRepository)..fetchDashboardData()),
        BlocProvider<FlashcardCubit>(create: (context) => FlashcardCubit(flashcardRepository)),
        BlocProvider<NoteCubit>(create: (context) => NoteCubit(noteRepository)..fetchNotes()),
      ],
      child: MaterialApp(
        title: 'Pamagi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        ),
        initialRoute: initialRoute, // Gunakan hasil cek token di sini
        routes: {
          '/': (context) => LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const MainLayout(),
        },
      ),
    );
  }
}