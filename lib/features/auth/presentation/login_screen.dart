import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/auth/logic/auth_cubit.dart';
import 'package:pamagi/features/auth/logic/auth_state.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthSuccess) {
                  Navigator.pushReplacementNamed(context, '/home');
                } else if (state is AuthFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message, style: const TextStyle(color: Colors.white)),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFFE3F2FD),
                      child: Icon(Icons.library_books, size: 40, color: Colors.blue),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF009688),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Continue your language journey.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Username/Email',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009688)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: identifierController,
                      decoration: InputDecoration(
                        hintText: 'e.g. alex@example.com',
                        hintStyle: const TextStyle(color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Password',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009688)),
                        ),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          child: const Text('Forgot Password?', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        suffixIcon: const Icon(Icons.visibility, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: state is AuthLoading
                          ? null
                          : () {
                        context.read<AuthCubit>().loginUser(
                          identifierController.text,
                          passwordController.text,
                        );
                      },
                      child: state is AuthLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : const Text(
                        'Login',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                        GestureDetector(
                          onTap: () {
                            // Ini perintah untuk pindah ke halaman Register
                            Navigator.pushNamed(context, '/register');
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009688)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ); // <--- Ini bagian yang sudah aku perbaiki
              },
            ),
          ),
        ),
      ),
    );
  }
}