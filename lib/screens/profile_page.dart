import '../services/versi_app.dart';
import 'package:flutter/material.dart';
import '../utils/tanpa_spasi.dart';
import '../theme/app_tokens.dart';
import '../widgets/sportago_ui.dart';
import 'package:flutter/services.dart';
import 'favorite_venues_page.dart';
import 'edit_profile_page.dart';
import 'notifications_page.dart';
import 'about_page.dart';
import 'login_page.dart';
import 'chat_history_page.dart';
import 'change_password_page.dart';
import '../services/auth_service.dart';
import '../services/push_notifikasi.dart';
import '../services/booking_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // User data dari AuthService
  String get _userName => AuthService.currentUser?.name ?? "User";
  String get _userEmail => AuthService.currentUser?.email ?? "-";
  String get _userPhone => AuthService.currentUser?.phone ?? "-";
  String get _memberSince {
    final createdAt = AuthService.currentUser?.createdAt;
    if (createdAt != null) {
      return _formatMonth(createdAt);
    }
    return "-";
  }

  // Helper format bulan Indonesia
  String _formatMonth(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // Data statistik dari database
  int _totalBookings = 0;
  int _completedBookings = 0;
  int _totalSpent = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  /// Ringkasan riwayat memesan.
  ///
  /// Dulu ketiganya dihitung dari HALAMAN PERTAMA saja, kecuali "Total
  /// Booking" yang diambil dari `pagination.total`. Halaman berisi 15
  /// baris, jadi begitu pemesan punya booking ke-16 angkanya berhenti
  /// nyambung: totalnya benar, "Selesai" dan "Total Belanja" membeku di
  /// 15 booking pertama. Tiga angka berdampingan yang saling
  /// bertentangan, dan yang paling sering memesan justru yang paling
  /// salah.
  Future<void> _loadUserStats() async {
    setState(() => _isLoadingStats = true);

    try {
      int total = 0;
      int completed = 0;
      double spent = 0;
      int halaman = 1;

      // Batas aman supaya akun dengan riwayat panjang tidak membuat
      // layar Profil menggantung tanpa ujung.
      const maksHalaman = 20;
      const perHalaman = 100;

      while (halaman <= maksHalaman) {
        final result = await BookingService.getMyBookings(
          page: halaman,
          perPage: perHalaman,
        );

        if (!result.success || result.bookings == null) break;

        for (final booking in result.bookings!) {
          total++;
          if (booking.status == 'completed') {
            completed++;
            spent += booking.totalPrice;
          } else if (booking.status == 'confirmed' ||
              booking.status == 'checked_in') {
            spent += booking.totalPrice;
          }
        }

        final terakhir = result.pagination?['last_page'];
        if (terakhir is int && halaman >= terakhir) break;
        if (result.bookings!.length < perHalaman) break;
        halaman++;
      }

      if (mounted) {
        setState(() {
          _totalBookings = total;
          _completedBookings = completed;
          _totalSpent = spent.toInt();
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.sunken,
      body: SafeArea(
        // Bilah navigasi menumpuk di atas isi layar sejak
        // targetSdk 35. top:false karena kepala pekat sudah
        // menyisihkan bagian atasnya sendiri.
        top: false,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          // Kepala selalu hijau pekat, jadi ikon bilah status selalu
          // terang, di tema mana pun.
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: RefreshIndicator(
            onRefresh: _loadUserStats,
            color: context.c.accent,
            backgroundColor: context.c.raised,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  // Kartu angka menumpang ke tepi bawah kepala.
                  Transform.translate(
                    offset: const Offset(0, -36),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildStatsSection(),
                          const SizedBox(height: 8),
                          _buildMenuSection(),
                          const SizedBox(height: 20),
                          _buildLogoutSection(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _inisial {
    final bagian = _userName.trim().split(RegExp(r'\s+'));
    if (bagian.isEmpty || bagian.first.isEmpty) return 'S';
    if (bagian.length >= 2) {
      return '${bagian[0][0]}${bagian[1][0]}'.toUpperCase();
    }
    return bagian.first[0].toUpperCase();
  }

  // Kepala hijau pekat: avatar inisial, nama, kontak, dan "Member sejak".
  Widget _buildProfileHeader() {
    final media = context.c.onMedia;
    return KepalaPekat(
      judul: "Profil",
      jarakBawah: 60,
      bawah: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 68,
                height: 68,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SportagoColors.pekatNaik,
                  border: Border.all(color: SportagoColors.volt, width: 2),
                ),
                child: Text(
                  _inisial,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: SportagoColors.volt,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: media.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: media.inkSoft, fontSize: 13),
                    ),
                    if (_userPhone != "-") ...[
                      const SizedBox(height: 2),
                      Text(
                        _userPhone,
                        style: TextStyle(color: media.inkSoft, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // "Member sejak" saja, selebar kepala.
          //
          // Di sebelahnya dulu ada lencana "Level: Silver".
          // Sportago tidak punya sistem tingkatan member sama
          // sekali — tidak di server, tidak di database, dan
          // tidak ada satu pun keuntungan yang melekat
          // padanya. Angkanya dikarang di app dari ambang
          // belanja yang ditulis di sini (500rb Silver, 2jt
          // Gold, 5jt Platinum). Pemesan yang melihat dirinya
          // "Silver" wajar bertanya dapat apa, dan tidak ada
          // jawabannya.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: SportagoColors.pekatNaik,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: SportagoColors.volt,
                ),
                const SizedBox(width: 8),
                Text(
                  "Member sejak",
                  style: TextStyle(fontSize: 12, color: media.inkSoft),
                ),
                const Spacer(),
                Text(
                  _memberSince,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: media.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ringkasan riwayat memesan dalam satu kartu.
  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return Kartu(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: CircularProgressIndicator(
            color: context.c.accent,
            strokeWidth: 2,
          ),
        ),
      );
    }

    // Satu kartu berisi tiga angka, bukan dua kartu berdampingan lalu
    // satu kartu yatim selebar layar di bawahnya. Ketiganya bercerita
    // tentang hal yang sama — riwayat memesan — jadi tidak ada alasan
    // yang satu dipisah sendirian.
    return Kartu(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _kolomStat(
                icon: Icons.confirmation_number_outlined,
                title: "Booking",
                value: "$_totalBookings",
                nada: Nada.aksen,
              ),
            ),
            _garis(),
            Expanded(
              child: _kolomStat(
                icon: Icons.check_circle_outline,
                title: "Selesai",
                value: "$_completedBookings",
                nada: Nada.ok,
              ),
            ),
            _garis(),
            Expanded(
              child: _kolomStat(
                icon: Icons.account_balance_wallet_outlined,
                title: "Total Belanja",
                value: _formatCurrency(_totalSpent),
                nada: Nada.aksen,
                kecil: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _garis() => Container(width: 1, color: context.c.line);

  Widget _kolomStat({
    required IconData icon,
    required String title,
    required String value,
    required Nada nada,
    bool kecil = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          UbinIkon(icon, nada: nada, ukuran: 36),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: kecil ? 14 : 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: context.c.ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: context.c.inkSoft),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Menu Section
  Widget _buildMenuSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const JudulBagian("Akun"),
        Kartu(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.person_outline_rounded,
                title: "Ubah Profil",
                subtitle: "Update informasi personal",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  );
                  if (mounted) {
                    setState(() {});
                    _loadUserStats();
                  }
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.lock_outline_rounded,
                title: "Ubah Password",
                subtitle: "Ganti password akun",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const JudulBagian(
          "Aktivitas",
          padding: EdgeInsets.fromLTRB(4, 20, 4, 12),
        ),
        Kartu(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.favorite_border_rounded,
                title: "Venue Favorit",
                subtitle: "Venue yang kamu tandai hati",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoriteVenuesPage(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.chat_outlined,
                title: "Riwayat Pesan",
                subtitle: "Lihat histori chat dengan venue",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatHistoryPage(),
                    ),
                  );
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.notifications_outlined,
                title: "Notifikasi",
                subtitle: "Pengaturan notifikasi",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const JudulBagian(
          "Lainnya",
          padding: EdgeInsets.fromLTRB(4, 20, 4, 12),
        ),
        Kartu(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildMenuItem(
                icon: Icons.info_outline_rounded,
                title: "Tentang Sportago",
                subtitle: VersiApp.tampil,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
              _buildDivider(),
              _buildMenuItem(
                icon: Icons.delete_outline_rounded,
                title: "Hapus Akun",
                subtitle: "Hapus akun secara permanen",
                onTap: () => _showDeleteAccountDialog(),
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            UbinIkon(
              icon,
              ukuran: 42,
              nada: isDestructive ? Nada.danger : Nada.aksen,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDestructive ? context.c.danger : context.c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: context.c.inkSoft, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: context.c.inkSoft),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      height: 1,
      color: context.c.line,
    );
  }

  // Logout Section
  Widget _buildLogoutSection() {
    // Garis merah, bukan blok merah penuh: keluar akun bukan aksi yang
    // merusak data, jadi tidak perlu berteriak lebih keras dari menu
    // lain. Merahnya tetap supaya terbaca sebagai pintu keluar.
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(),
        icon: Icon(Icons.logout_rounded, color: context.c.danger, size: 20),
        label: Text(
          "Keluar dari Akun",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: context.c.danger,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: context.c.raised,
          side: BorderSide(color: context.c.danger.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User harus pilih salah satu tombol
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: context.c.raised,
            border: Border.all(color: context.c.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Logout dengan animasi
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: context.c.dangerSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  size: 40,
                  color: context.c.danger,
                ),
              ),

              const SizedBox(height: 20),

              // Title
              Text(
                "Keluar dari Akun?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.c.ink,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                "Anda akan keluar dari akun Sportago dan perlu login kembali untuk mengakses aplikasi.",
                style: TextStyle(
                  fontSize: 14,
                  color: context.c.inkSoft,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // Tombol Batal
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.c.lineStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        "Batal",
                        style: TextStyle(
                          color: context.c.inkSoft,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Tombol Logout
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _performLogout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.c.danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Ya, Keluar",
                        style: TextStyle(
                          color: SportagoColors.pure,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _performLogout() async {
    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.c.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: context.c.accent),
            SizedBox(height: 16),
            Text(
              "Sedang keluar...",
              style: TextStyle(color: context.c.inkSoft, fontSize: 14),
            ),
          ],
        ),
      ),
    );

    // Panggil API logout
    // Dilepas sebelum token auth hilang, karena endpoint pelepasannya
    // membutuhkan token itu. Tanpa ini HP yang sudah logout terus
    // menerima notifikasi pemilik akun sebelumnya, termasuk kode
    // pemesanan dan nominal uang.
    await PushNotifikasi.lepaskan();
    await AuthService.logout();

    if (mounted) {
      Navigator.pop(context); // Tutup loading dialog

      // Tampilkan success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: SportagoColors.volt),
              SizedBox(width: 12),
              Text("Berhasil keluar dari akun"),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );

      // Navigate ke login page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showDeleteAccountDialog() {
    final TextEditingController passwordController = TextEditingController();
    final TextEditingController otpController = TextEditingController();
    bool isLoading = false;
    bool obscurePassword = true;
    // Akun Google tidak pernah memilih kata sandinya sendiri, jadi
    // pembuktiannya lewat kode yang dikirim ke surel akun itu.
    final bool pakaiGoogle = AuthService.currentUser?.masukLewatGoogle ?? false;
    String? otpToken;
    String? pesanGalat;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: context.c.raised,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: context.c.line),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warning Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.c.danger.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: context.c.danger,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    "Hapus Akun?",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.c.ink,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Warning text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.c.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.c.danger),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: context.c.danger,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Tindakan ini tidak dapat dibatalkan. Semua data akan dihapus permanen.",
                            style: TextStyle(
                              color: context.c.danger,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (pesanGalat != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.c.dangerSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.c.danger),
                      ),
                      child: Text(
                        pesanGalat!,
                        style: TextStyle(
                          color: context.c.danger,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (pakaiGoogle)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Kode Verifikasi",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: context.c.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          otpToken == null
                              ? "Akun kamu masuk lewat Google. Kami kirim kode ke emailmu."
                              : "Kode sudah dikirim ke emailmu.",
                          style: TextStyle(
                            fontSize: 12,
                            color: context.c.inkSoft,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (otpToken == null)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        isLoading = true;
                                        pesanGalat = null;
                                      });
                                      final hasil =
                                          await AuthService.mintaOtpHapusAkun();
                                      if (!context.mounted) return;
                                      setDialogState(() {
                                        isLoading = false;
                                        if (hasil.success) {
                                          otpToken =
                                              hasil.data?['token'] as String?;
                                        } else {
                                          pesanGalat =
                                              hasil.message ??
                                              'Gagal mengirim kode. Coba lagi.';
                                        }
                                      });
                                    },
                              icon: const Icon(Icons.mail_outline, size: 18),
                              label: const Text("Kirim kode ke email"),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(color: context.c.line),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                        else
                          TextField(
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: context.c.ink),
                            decoration: InputDecoration(
                              hintText: "6 digit kode",
                              hintStyle: TextStyle(color: context.c.inkSoft),
                              prefixIcon: Icon(
                                Icons.pin_outlined,
                                color: context.c.inkSoft,
                              ),
                              filled: true,
                              fillColor: context.c.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.c.line),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.c.line),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.c.danger),
                              ),
                            ),
                          ),
                      ],
                    )
                  else
                    // Password confirmation
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Konfirmasi Password",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: context.c.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          inputFormatters: const [TanpaSpasi()],
                          style: TextStyle(color: context.c.ink),
                          decoration: InputDecoration(
                            hintText: "Masukkan password",
                            hintStyle: TextStyle(color: context.c.inkSoft),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: context.c.inkSoft,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: context.c.inkSoft,
                              ),
                              onPressed: () {
                                setDialogState(
                                  () => obscurePassword = !obscurePassword,
                                );
                              },
                            ),
                            filled: true,
                            fillColor: context.c.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.c.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.c.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: context.c.danger),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: context.c.lineStrong),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Batal",
                            style: TextStyle(
                              color: context.c.inkSoft,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (pakaiGoogle) {
                                    if (otpToken == null) {
                                      setDialogState(
                                        () => pesanGalat =
                                            'Kirim kode ke email dulu.',
                                      );
                                      return;
                                    }
                                    if (otpController.text.trim().isEmpty) {
                                      setDialogState(
                                        () => pesanGalat = 'Kode harus diisi.',
                                      );
                                      return;
                                    }
                                  } else if (passwordController.text.isEmpty) {
                                    setDialogState(
                                      () =>
                                          pesanGalat = 'Password harus diisi.',
                                    );
                                    return;
                                  }

                                  setDialogState(() {
                                    isLoading = true;
                                    pesanGalat = null;
                                  });

                                  final hasil = await AuthService.hapusAkun(
                                    password: pakaiGoogle
                                        ? null
                                        : passwordController.text,
                                    otpToken: pakaiGoogle ? otpToken : null,
                                    otpCode: pakaiGoogle
                                        ? otpController.text.trim()
                                        : null,
                                  );

                                  if (!context.mounted) return;
                                  setDialogState(() => isLoading = false);

                                  if (hasil.berhasil) {
                                    Navigator.pop(context);
                                    _showDeleteSuccessAndLogout(hasil.pesan);
                                    return;
                                  }

                                  // Termasuk keadaan "tertahan": dialognya
                                  // sengaja tetap terbuka supaya alasannya
                                  // terbaca, bukan berkelebat sebagai
                                  // snackbar lalu hilang.
                                  setDialogState(
                                    () => pesanGalat = hasil.pesan,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.c.danger,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: SportagoColors.pure,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Hapus Akun",
                                  style: TextStyle(
                                    color: SportagoColors.pure,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteSuccessAndLogout(String pesan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: context.c.raised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.c.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.c.ok.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: context.c.ok,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                "Akun Dihapus",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.c.ink,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                pesan,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.c.inkSoft,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.c.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "OK",
                    style: TextStyle(
                      color: context.c.onAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function untuk format currency
  String _formatCurrency(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }
}
