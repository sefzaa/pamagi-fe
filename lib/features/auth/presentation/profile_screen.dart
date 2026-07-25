import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pamagi/core/api_client.dart';
import 'package:pamagi/core/secure_storage_helper.dart';
import 'package:pamagi/features/auth/data/auth_repository.dart';
import 'package:pamagi/features/auth/logic/auth_cubit.dart';
import 'package:pamagi/features/auth/presentation/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.dio.get('/users/me');
      setState(() {
        profileData = response.data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load profile data')));
      }
    }
  }

  Future<void> _logout() async {
    try {
      final apiClient = ApiClient();
      await apiClient.dio.post('/logout');
    } catch (e) {
      // Abaikan error backend
    } finally {
      await SecureStorageHelper.clearTokens();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    }
  }

  void _openEditProfile() async {
    if (profileData == null) return;
    final authRepo = AuthRepository(ApiClient());
    final isUpdated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => AuthCubit(authRepo),
          child: EditProfileScreen(profileData: profileData!),
        ),
      ),
    );
    if (isUpdated == true) {
      _fetchProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00AA5B)));
    }

    if (profileData == null) {
      return Center(
        child: ElevatedButton(
          onPressed: _logout,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Force Logout', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final targets = profileData!['target_languages'] as List? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      // APPBAR DIHAPUS agar tidak ada double header
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 12),
            // LINGKARAN PROFILE DENGAN BADGE ICON EDIT
            GestureDetector(
              onTap: _openEditProfile,
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(Icons.person, size: 50, color: Color(0xFF00AA5B)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00AA5B),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(profileData!['name'] ?? 'No Name', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('@${profileData!['username'] ?? 'username'}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text('"${profileData!['slogan'] ?? 'Consistency is key to fluency.'}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Color(0xFF00AA5B))),
            const SizedBox(height: 32),

            _buildInfoTile('Email', profileData!['email'] ?? '-'),
            _buildInfoTile('Subscription', profileData!['subscription_status'] ?? 'FREE'),
            _buildInfoTile('Native Language', '${profileData!['native_flag_icon'] ?? ''} ${profileData!['native_language'] ?? '-'}'),

            const SizedBox(height: 16),
            const Align(alignment: Alignment.centerLeft, child: Text('Learning:', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            ...targets.map((t) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  Text(t['flag_icon'] ?? '🌍', style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Text(t['language_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            )),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}