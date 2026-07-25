import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_picker/country_picker.dart';
import 'package:pamagi/features/auth/logic/auth_cubit.dart';
import 'package:pamagi/features/auth/logic/auth_state.dart';
import 'package:pamagi/features/home/logic/home_cubit.dart';

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
  final sloganController = TextEditingController(); // Input Slogan

  bool _obscurePassword = true;

  String? nativeLanguageCode;
  String? nativeLanguageName;
  String? nativeFlagIcon;
  List<Map<String, String>> targetLanguages = [];

  void _pickNativeLanguage() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() {
          nativeLanguageCode = country.countryCode;
          nativeLanguageName = country.name;
          nativeFlagIcon = country.flagEmoji;
        });
      },
    );
  }

  void _pickTargetLanguage() {
    if (targetLanguages.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maximum 2 target languages allowed!')));
      return;
    }
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        if (targetLanguages.any((lang) => lang['language_code'] == country.countryCode)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Language already added!')));
          return;
        }
        setState(() {
          targetLanguages.add({'language_code': country.countryCode, 'language_name': country.name, 'flag_icon': country.flagEmoji});
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: BlocConsumer<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is AuthSuccess) {
                  // TRIGGER FETCH DATA SETELAH REGISTER SUKSES
                  context.read<HomeCubit>().fetchDashboardData();

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
                    Image.asset('assets/images/logo.png', height: 80),
                    const SizedBox(height: 16),
                    const Text('Create Account', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                    const Text('Continue your language journey', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 24),

                    _buildTextField('Name', 'Your full name', nameController),
                    _buildTextField('Username', 'Choose a handle', usernameController),
                    _buildTextField('Email', 'example@email.com', emailController, TextInputType.emailAddress),

                    // Password Field
                    const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'At least 8 characters',
                        hintStyle: const TextStyle(color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00AA5B))),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField('WhatsApp Number', '+1...', noWaController, TextInputType.phone),

                    const Text('Native Language', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickNativeLanguage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(nativeLanguageName != null ? '$nativeFlagIcon  $nativeLanguageName' : 'Select native language', style: TextStyle(color: nativeLanguageName == null ? Colors.grey : Colors.black, fontSize: 16)),
                            const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Target Language', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
                    const SizedBox(height: 8),
                    ...targetLanguages.asMap().entries.map((entry) {
                      int idx = entry.key;
                      var lang = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(color: Colors.grey.shade100, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${lang['flag_icon']}  ${lang['language_name']}', style: const TextStyle(fontSize: 16)),
                              GestureDetector(onTap: () => setState(() => targetLanguages.removeAt(idx)), child: const Icon(Icons.close, color: Colors.red, size: 20)),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (targetLanguages.length < 2)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _pickTargetLanguage,
                          icon: const Icon(Icons.add, color: Color(0xFF00AA5B)),
                          label: const Text('Add Target Language', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
                        ),
                      ),
                    const SizedBox(height: 16),

                    _buildTextField('Slogan (optional)', 'Enter your slogan', sloganController),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AA5B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: state is AuthLoading ? null : () {
                        // 1. Ambil semua teks
                        final name = nameController.text.trim();
                        final username = usernameController.text.trim();
                        final email = emailController.text.trim();
                        final password = passwordController.text;

                        // 2. Validasi berurutan dari atas ke bawah secara lokal
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required.'), backgroundColor: Colors.red));
                          return;
                        }
                        if (username.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username is required.'), backgroundColor: Colors.red));
                          return;
                        }
                        if (email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valid email is required.'), backgroundColor: Colors.red));
                          return;
                        }
                        if (password.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters.'), backgroundColor: Colors.red));
                          return;
                        }
                        if (nativeLanguageCode == null) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your native language.'), backgroundColor: Colors.red));
                          return;
                        }
                        if (targetLanguages.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 target language.'), backgroundColor: Colors.red));
                          return;
                        }

                        // 3. Jika semua lulus, baru kirim ke backend
                        final body = {
                          "name": name,
                          "username": username,
                          "email": email,
                          "password": password,
                          "no_wa": noWaController.text.trim(),
                          "native_language": nativeLanguageCode,
                          "native_flag_icon": nativeFlagIcon,
                          "target_languages": targetLanguages,
                          "slogan": sloganController.text.trim(),
                        };
                        context.read<AuthCubit>().registerUser(body);
                      },
                      child: state is AuthLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? ", style: TextStyle(color: Colors.grey)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text('Login', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
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

  Widget _buildTextField(String label, String hint, TextEditingController controller, [TextInputType type = TextInputType.text]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: type,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF00AA5B))),
            ),
          ),
        ],
      ),
    );
  }
}