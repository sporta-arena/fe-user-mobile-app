/// Keterangan kecil di sebelah nominal biaya admin payment gateway.
///
/// Dipisah dari widget karena kalimatnya pernah salah tanpa ketahuan:
/// tertulis "0.7% dari harga lapangan", padahal dasar hitungannya
/// (harga lapangan + biaya platform), sama seperti BookingService di
/// backend. Pemesan yang mengalikan sendiri menemukan Rp 2.100
/// sedangkan yang ditagih Rp 2.240, dan selisih tanpa penjelasan itu
/// persis jenis kesalahan yang paling mahal di halaman pembayaran.
String keteranganBiayaGateway({
  required String? tipeBiaya,
  required double nilai,
}) {
  if (tipeBiaya != 'percent') return ' (biaya tetap)';
  final persen = (nilai * 100).toStringAsFixed(1);
  return ' ($persen% dari harga lapangan + biaya platform)';
}
