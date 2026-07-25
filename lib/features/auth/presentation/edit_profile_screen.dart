import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_picker/country_picker.dart';
import 'package:pamagi/features/auth/logic/auth_cubit.dart';
import 'package:pamagi/features/auth/logic/auth_state.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;

  const EditProfileScreen({super.key, required this.profileData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController usernameController;
  late TextEditingController noWaController;
  late TextEditingController sloganController;

  String? nativeLanguageCode;
  String? nativeFlagIcon;
  List<Map<String, String>> targetLanguages = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.profileData['name'] ?? '');
    usernameController = TextEditingController(text: widget.profileData['username'] ?? '');
    noWaController = TextEditingController(text: widget.profileData['no_wa'] ?? '');
    sloganController = TextEditingController(text: widget.profileData['slogan'] ?? '');

    nativeLanguageCode = widget.profileData['native_language'];
    nativeFlagIcon = widget.profileData['native_flag_icon'];

    if (widget.profileData['target_languages'] != null) {
      final targets = widget.profileData['target_languages'] as List;
      for (var t in targets) {
        targetLanguages.add({
          'language_code': t['language_code'] ?? '',
          'language_name': t['language_name'] ?? '',
          'flag_icon': t['flag_icon'] ?? '',
        });
      }
    }
  }

  void _pickNativeLanguage() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() {
          nativeLanguageCode = country.countryCode;
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
          targetLanguages.add({
            'language_code': country.countryCode,
            'language_name': country.name,
            'flag_icon': country.flagEmoji
          });
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Color(0xFF00AA5B), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF00AA5B)),
        elevation: 0,
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Color(0xFF00AA5B)));
            Navigator.pop(context, true);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField('Name', nameController),
                _buildTextField('Username', usernameController),
                _buildTextField('WhatsApp Number', noWaController, TextInputType.phone),
                _buildTextField('Slogan', sloganController),

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
                        Text(nativeLanguageCode != null ? '$nativeFlagIcon  $nativeLanguageCode' : 'Select native language', style: const TextStyle(fontSize: 16)),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Target Languages (Max 2)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00AA5B))),
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

                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00AA5B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: state is AuthLoading ? null : () {
                    if (targetLanguages.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least 1 target language!')));
                      return;
                    }
                    final body = {
                      "name": nameController.text,
                      "username": usernameController.text,
                      "no_wa": noWaController.text,
                      "slogan": sloganController.text,
                      "native_language": nativeLanguageCode ?? '',
                      "native_flag_icon": nativeFlagIcon ?? '',
                      "target_languages": targetLanguages,
                    };
                    context.read<AuthCubit>().updateProfile(body);
                  },
                  child: state is AuthLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, [TextInputType type = TextInputType.text]) {
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