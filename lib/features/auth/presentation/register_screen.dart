import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_picker/country_picker.dart'; // Import library baru kita!
import 'package:pamagi/features/auth/logic/auth_cubit.dart';
import 'package:pamagi/features/auth/logic/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final noWaController = TextEditingController();

  // Variabel untuk menyimpan negara yang dipilih
  String? selectedRegionName; // Untuk ditampilkan di layar (misal: Indonesia)
  String? selectedRegionCode; // Untuk dikirim ke database BE (misal: ID)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2C2C),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                    SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                  );
                }
              },
              builder: (context, state) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Color(0xFFE3F2FD),
                      child: Icon(Icons.library_books, size: 35, color: Colors.blue),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Create Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF009688)),
                    ),
                    const Text(
                      'Join our global community.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),

                    _buildTextField('Name', 'Your full name', nameController),
                    _buildTextField('Username', 'Choose a handle', usernameController),
                    _buildTextField('Email', 'example@email.com', emailController, TextInputType.emailAddress),
                    _buildTextField('Password', 'At least 8 characters', passwordController, TextInputType.visiblePassword, true),
                    _buildTextField('WhatsApp Number', '+1...', noWaController, TextInputType.phone),

                    // --- BAGIAN REGION ---
                    const Text('Region', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009688))),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          showPhoneCode: false,
                          onSelect: (Country country) {
                            setState(() {
                              // Simpan nama untuk UI, simpan kode untuk Backend
                              selectedRegionName = country.name;
                              selectedRegionCode = country.countryCode;
                            });
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedRegionName ?? 'Select region', // Tampilkan namanya di sini
                              style: TextStyle(
                                color: selectedRegionName == null ? Colors.grey : Colors.black,
                                fontSize: 16,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- BAGIAN TOMBOL SIGN UP ---
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C853),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: state is AuthLoading ? null : () {
                        if (selectedRegionCode == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih region dulu bro!')));
                          return;
                        }

                        final body = {
                          "name": nameController.text,
                          "username": usernameController.text,
                          "email": emailController.text,
                          "password": passwordController.text,
                          "no_wa": noWaController.text,
                          "region": selectedRegionCode, // SEKARANG MENGIRIM KODE (Contoh: ID, MY, SG)
                        };
                        context.read<AuthCubit>().registerUser(body);
                      },
                      child: state is AuthLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009688))),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, [TextInputType type = TextInputType.text, bool isPassword = false]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF009688))),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: type,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
              suffixIcon: isPassword ? const Icon(Icons.visibility, color: Colors.grey) : null,
            ),
          ),
        ],
      ),
    );
  }
}