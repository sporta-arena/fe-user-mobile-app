import 'package:flutter/material.dart';
import 'change_password_page.dart';
import '../services/auth_service.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Edit Profil", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
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
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
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
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
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
                          color: const Color(0xFF0047FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
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
                    color: Color(0xFF0047FF), 
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
                  backgroundColor: const Color(0xFF0047FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFF0047FF).withOpacity(0.4),
                ),
                child: _isLoading 
                  ? const SizedBox(
                      height: 24, 
                      width: 24, 
                      child: CircularProgressIndicator(
                        color: Colors.white, 
                        strokeWidth: 2
                      )
                    )
                  : const Text(
                      "SIMPAN PERUBAHAN", 
                      style: TextStyle(
                        color: Colors.white, 
                        fontWeight: FontWeight.bold, 
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
            color: Colors.black87
          )
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isReadOnly ? Colors.grey[100] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isReadOnly ? [] : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05), 
                blurRadius: 10, 
                offset: const Offset(0, 4)
              )
            ],
          ),
          child: TextField(
            controller: controller,
            readOnly: isReadOnly,
            keyboardType: inputType,
            style: TextStyle(
              color: isReadOnly ? Colors.grey[600] : Colors.black
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon, 
                color: isReadOnly ? Colors.grey : const Color(0xFF0047FF)
              ),
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none, // Hilangkan garis default
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF0047FF)),
              ),
              filled: true,
              fillColor: isReadOnly ? Colors.grey[100] : Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}