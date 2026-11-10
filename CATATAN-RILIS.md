# Catatan Rilis — Sportago (App Pemesan)

## 1.2.3 (versionCode 6)

Naik dari 1.2.2 (versionCode 5).

### Untuk Play Console (bahasa Indonesia, ≤500 karakter)

```
Biaya platform lebih ringan:
• Biaya platform turun dari 8% jadi 5%, paling sedikit Rp2.000 dan paling
  banyak Rp10.000 per pemesanan.
• Rincian biaya di layar konfirmasi kini sama persis dengan yang ditagih.
• Pusat Bantuan sekarang bisa dihubungi lewat WhatsApp.
```

### Rinciannya

Server sudah menagih 5% (min Rp2.000, maks Rp10.000) sejak 10 Nov 2026.
Versi sebelumnya masih menghitung perkiraan 8% maks Rp20.000 di layar
konfirmasi, jadi pemesan melihat total lebih mahal daripada yang ditagih.
WhatsApp resmi 0817-7091-4140 ditambahkan di Pusat Bantuan.

## 1.1.1 (versionCode 3)

Naik dari 1.1.0 (versionCode 2).

### Untuk Play Console (bahasa Indonesia, ≤500 karakter)

```
Perbaikan halaman Profil:
• Statistik booking kini dihitung dari seluruh riwayat, bukan halaman
  pertama saja. Sebelumnya "Selesai" dan "Total Belanja" berhenti di 15
  booking pertama, jadi makin sering memesan makin meleset angkanya.
• Tampilan statistik dirapikan jadi satu kartu yang mudah dibaca.
• Nomor versi aplikasi kini selalu benar.
• Lencana "Level" dihapus karena Sportago belum punya program membership.
```

### Rinciannya

**Statistik profil salah untuk pemakai aktif.** "Total Booking" diambil
dari `pagination.total`, tapi "Selesai" dan "Total Belanja" dijumlahkan
dari halaman pertama saja. Satu halaman berisi 15 baris, jadi mulai
booking ke-16 ketiga angka itu berhenti sepakat. Sekarang seluruh halaman
dijumlahkan (100 per permintaan, batas aman 20 halaman).

**Lencana "Level" dicabut.** Lencana itu menampilkan Silver/Gold/Platinum
dari ambang belanja yang ditulis mati di dalam aplikasi. Tidak ada sistem
tingkatan member di server — tidak ada tabel, tidak ada aturan, dan tidak
ada satu pun keuntungan yang melekat padanya. Menampilkan status yang
tidak memberi apa-apa hanya mengundang pertanyaan yang tidak ada
jawabannya. Kalau program membership dibuat nanti, ambang dan
keuntungannya harus datang dari server.

**Tata letak statistik.** Dua kartu berdampingan lalu satu kartu yatim
selebar layar diganti satu kartu berisi tiga kolom.

**Nomor versi.** Dulu ditulis tangan "1.0.0" di dua tempat (menu Profil
dan halaman Tentang) sementara aplikasinya sudah 1.1.0. Sekarang dibaca
dari paketnya sendiri lewat `VersiApp`.

### Yang perlu diketahui penguji

- Tidak ada perubahan pada alur booking maupun pembayaran.
- Pembayaran masih memakai sandbox Duitku; menunggu kunci produksi.
