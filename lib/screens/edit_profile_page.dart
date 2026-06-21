import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'change_password_page.dart';
import '../services/auth_service.dart';
import '../constants/colors.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // --- CONTROLLERS ---
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ambil data user yang sedang login dari AuthService
    final user = AuthService.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // --- FUNGSI SIMPAN ---
  void _saveProfile() async {
    setState(() => _isLoading = true);

    // Panggil API untuk update profile
    final result = await AuthService.updateProfile(
      name: _nameController.text,
      phone: _phoneController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        // Tampilkan Pesan Sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil berhasil diperbarui!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Kembali ke halaman sebelumnya
        Navigator.pop(context);
      } else {
        // Tampilkan Pesan Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Gagal memperbarui profil"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          "Edit Profil",
          style: TextStyle(color: AppColors.onDark, fontWeight: FontWeight.bold)
        ),
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.onDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- 1. SEKSI FOTO PROFIL ---
            Center(
              child: Stack(
                children: [
                  // Foto Utama
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.surfaceBorder, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5)
                        )
                      ],
                      image: AuthService.currentUser?.avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(AuthService.currentUser!.avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: AuthService.currentUser?.avatarUrl == null
                        ? const Icon(Icons.person, size: 50, color: AppColors.onDarkMuted)
                        : null,
                  ),
                  
                  // Tombol Kamera Kecil
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: Implementasi Image Picker (Ambil dari Galeri)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Fitur Ganti Foto (Coming Soon)")),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.brandYellow,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bg, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: AppColors.ink, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // --- 2. FORM INPUT ---
            _buildTextField(
              label: "Nama Lengkap",
              controller: _nameController,
              icon: Icons.person_outline,
            ),
            
            const SizedBox(height: 20),
            
            _buildTextField(
              label: "Email Address",
              controller: _emailController,
              icon: Icons.email_outlined,
              isReadOnly: true, // Email biasanya tidak boleh ganti sembarangan
              hint: "Hubungi admin untuk ganti email",
            ),
            
            const SizedBox(height: 20),
            
            _buildTextField(
              label: "Nomor WhatsApp",
              controller: _phoneController,
              icon: Icons.phone_android_outlined,
              inputType: TextInputType.phone,
            ),
            
            const SizedBox(height: 20),
            
            // Link Ganti Password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Navigasi ke Halaman Ganti Password
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChangePasswordPage()),
                  );
                },
                child: const Text(
                  "Ganti Password?",
                  style: TextStyle(
                    color: AppColors.brandYellow,
                    fontWeight: FontWeight.bold
                  )
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // --- 3. TOMBOL SIMPAN ---
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.ink,
                        strokeWidth: 2
                      )
                    )
                  : const Text(
                      "SIMPAN PERUBAHAN",
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 16
                      )
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER WIDGET BUAT TEXTFIELD BIAR RAPI ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isReadOnly = false,
    TextInputType inputType = TextInputType.text,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.onDark
          )
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            readOnly: isReadOnly,
            keyboardType: inputType,
            style: TextStyle(
              color: isReadOnly ? AppColors.onDarkMuted : AppColors.onDark
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: isReadOnly ? AppColors.onDarkMuted : AppColors.brandYellow
              ),
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12, color: AppColors.onDarkMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none, // Hilangkan garis default
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.brandYellow),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
        ),
      ],
    );
  }
}