/// Pemeriksaan isian layar ganti password, sebelum apa pun dikirim.
///
/// Dipisah dari widget supaya bisa diuji, dan supaya batas panjangnya
/// tinggal di satu tempat. Layar lama memakai 6 karakter sementara
/// server memakai `min:8`, jadi ada rentang di mana aplikasi bilang
/// "boleh" dan server bilang "tidak", dan yang dibaca pengguna cuma
/// kegagalan tanpa sebab.
const int panjangMinimalPassword = 8;

String? periksaGantiPassword({
  required String lama,
  required String baru,
  required String ulangi,
}) {
  if (lama.isEmpty || baru.isEmpty || ulangi.isEmpty) {
    return 'Semua kolom wajib diisi.';
  }
  if (baru != ulangi) {
    return 'Password baru tidak cocok dengan ulangannya.';
  }
  if (baru.length < panjangMinimalPassword) {
    return 'Password baru minimal $panjangMinimalPassword karakter.';
  }
  if (baru == lama) {
    return 'Password baru harus berbeda dari password lama.';
  }
  return null;
}
