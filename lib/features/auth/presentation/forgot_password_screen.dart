import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/features/auth/logic/auth_cubit.dart';
import 'package:pamagi/features/auth/logic/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Pengontrol tahapan: 1 = Email, 2 = OTP, 3 = Password Baru
  int _currentStep = 1;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _savedEmail = '';
  String _resetToken = '';
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is AuthOtpSent) {
            setState(() {
              _savedEmail = _emailController.text.trim();
              _currentStep = 2; // Pindah ke Step OTP
            });
          } else if (state is AuthOtpVerified) {
            setState(() {
              _resetToken = state.resetToken; // Simpan tiket saktinya
              _currentStep = 3; // Pindah ke Step Password Baru
            });
          } else if (state is AuthPasswordResetSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password berhasil diubah! Silakan login.'), backgroundColor: Colors.green),
            );
            // Kembalikan ke halaman Login
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Image.asset('assets/images/logo.png', height: 60),
                const SizedBox(height: 32),

                // Judul dinamis tergantung Step
                Text(
                  _currentStep == 1 ? 'Lupa Password?'
                      : _currentStep == 2 ? 'Masukkan Kode OTP'
                      : 'Buat Password Baru',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B)),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentStep == 1 ? 'Masukkan email kamu untuk menerima kode pemulihan.'
                      : _currentStep == 2 ? 'Kode 6 digit telah dikirim ke\n$_savedEmail'
                      : 'Pastikan password baru kamu kuat dan aman.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),

                // WIDGET DINAMIS (Hanya muncul sesuai Step)
                if (_currentStep == 1) _buildEmailInput(),
                if (_currentStep == 2) _buildOtpInput(),
                if (_currentStep == 3) _buildNewPasswordInput(),

                const SizedBox(height: 32),

                // TOMBOL AKSI
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AA5B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: state is AuthLoading ? null : _handleActionButton,
                  child: state is AuthLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                    _currentStep == 1 ? 'Kirim Kode OTP'
                        : _currentStep == 2 ? 'Verifikasi'
                        : 'Simpan Password Baru',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- BAGIAN KOMPONEN INPUT ---

  Widget _buildEmailInput() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'e.g. alex@example.com',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00AA5B))),
      ),
    );
  }

  Widget _buildOtpInput() {
    return TextField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: '000000',
        counterText: '',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00AA5B))),
      ),
    );
  }

  Widget _buildNewPasswordInput() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Password baru',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00AA5B))),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
    );
  }

  // --- LOGIKA TOMBOL ---

  void _handleActionButton() {
    if (_currentStep == 1) {
      if (_emailController.text.isEmpty) return;
      context.read<AuthCubit>().requestForgotPasswordOTP(_emailController.text.trim());
    } else if (_currentStep == 2) {
      if (_otpController.text.length != 6) return;
      context.read<AuthCubit>().verifyOTP(_savedEmail, _otpController.text.trim());
    } else if (_currentStep == 3) {
      if (_passwordController.text.length < 6) return;
      context.read<AuthCubit>().resetPassword(_savedEmail, _resetToken, _passwordController.text);
    }
  }
}