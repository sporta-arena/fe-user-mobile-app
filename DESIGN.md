# DESIGN.md: Sportago

Ditranskrip dari sistem yang sudah berjalan, bukan dikarang:
`fe-web/src/app/globals.css` dan `partner-app/lib/theme/app_tokens.dart`.
Kalau dokumen ini dan kode berbeda, kodenya yang benar dan dokumen ini
yang harus dibetulkan.

Dial: ENERGY 1 / RHYTHM 2 / MOTION 1

## Identitas

Sportago adalah alat kerja untuk orang yang mengelola lapangan dan uang
hasil sewanya, bukan etalase produk. Nada yang dituju: tenang, padat,
bisa dipercaya. Yang dicari pengguna adalah kepastian ("booking masuk
tidak", "duit cair tidak"), jadi permukaan yang ramai justru menghalangi.

Yang membuat Sportago terlihat seperti Sportago dan bukan dasbor mana
pun: hijau lapangan sebagai satu satunya warna aksi di tema terang, volt
menggantikannya di tema gelap, dan struktur yang dibawa oleh garis tipis,
bukan oleh bayangan.

## Aturan pokok

**Komponen tidak pernah menyebut warna literal.** Komponen menyebut peran
(permukaan, teks, garis, aksen, status), dan lapisan token yang menentukan
nilainya menurut tema aktif. Di web lewat variabel CSS, di Flutter lewat
`context.c`.

Konsekuensinya: menambah warna baru berarti menambah token baru dengan
alasan tertulis, bukan menempelkan hex di tempat pemakaian.

## Warna

### Peran

| Peran | Untuk apa |
|---|---|
| `surface` | latar halaman |
| `raised` | kartu, panel, modal, sheet |
| `sunken` | bidang masuk ke dalam, baris zebra |
| `hoverSurface` | keadaan ditekan atau disorot |
| `inverse` / `onInverse` | blok kontras, tooltip |
| `ink` / `inkSoft` / `inkDim` | isi utama, penjelas, meta dan placeholder |
| `line` / `lineStrong` | garis pemisah dan garis tegas |
| `accent` dan turunannya | satu warna aksi per tema |
| `ok` `warn` `danger` `info` (+ `*Soft`) | keadaan, bukan kategori |

### Nilai

Tema terang: `surface #fbfcfb`, `raised #ffffff`, `sunken #f2f5f3`,
`ink #101e17`, `inkSoft #4a5c52`, `inkDim #7b8a82`, `line #dee7e1`,
`lineStrong #c3d2c9`, `accent #00733f`, `accentHover #005730`,
`accentSoft #eaf4ee`, `accentLine #a9cdb8`, `ok #12703f`, `warn #9a5b08`,
`danger #b3261e`, `info #0f5f76`.

Tema gelap: `surface #0a0b0e`, `raised #131519`, `sunken #08090b`,
`ink #e9ecef`, `inkSoft #98a1ab`, `inkDim #69727c`, `line #262a31`,
`lineStrong #363b44`, `accent #c5f400` (volt), `accentHover #d7ff3d`,
`accentSoft #1a1f08`, `accentLine #3f4d0a`, `ok #48d18a`, `warn #e0a312`,
`danger #ff6b62`, `info #4cc4e6`.

### Nilai yang tidak ikut tema

- `scrim #080c0a` (tirai di atas foto). Foto tidak berganti tema, jadi
  tirainya juga tidak. Pernah salah di web: tirai memakai token bertema,
  hasilnya gambar terbelah separuh terang separuh gelap.
- `pure #ffffff` untuk teks dan ikon di atas foto.
- `volt #c5f400` hanya di tempat yang memang selalu gelap (splash, konten
  di atas foto), bukan sebagai warna aksi umum.

### Sorotan data (khusus web)

`--highlight #5f7a00` dan `--highlight-soft #f2f7de` untuk angka dan grafik
di dasbor mitra. Volt murni tidak terbaca di atas putih, jadi di tema
terang harus digelapkan.

### Palet kategori, terpisah dari status

Enam warna untuk membedakan kategori (kartu komunitas, kartu event, ikon
judul bagian), saturasinya sengaja diturunkan supaya berdampingan dengan
hijau tanpa berteriak.

Terang: `#1f6f54` `#2a6f97` `#8a5a2b` `#6a4c93` `#9a5b08` `#14746f`
Gelap: `#5fd3a8` `#6cb6e0` `#d9a05b` `#b59be0` `#e0a312` `#5fc9c4`

Kenapa dipisah dari token status: memakai `danger` untuk badge "Populer"
membuat label netral terbaca sebagai peringatan, dan memaksa banyak
kategori ke sedikit token status membuat dua kategori tampil sama.

## Tipografi

Plus Jakarta Sans, satu keluarga untuk semua permukaan. Dipilih karena
bentuk angkanya jelas (layar ini penuh angka: harga, jam, saldo) dan
karakternya netral tanpa terasa generik.

Berat yang dipakai: 400 isi, 500 sampai 600 label dan judul kartu,
700 sampai 800 angka penting dan judul layar.

Tidak ada monospace besar sebagai gaya. Tidak ada label huruf besar
dengan jarak huruf lebar.

## Bentuk dan kedalaman

Radius 12 adalah bawaan (146 pemakaian di app mitra). 8 untuk elemen kecil
seperti badge dan input, 16 sampai 20 untuk sheet dan panel besar. Tidak
ada pill di semua elemen sekaligus.

**Struktur dibawa garis, bukan bayangan.** Bayangan tipis dan jarang,
hanya untuk menandai elevasi yang benar benar ada (sheet di atas halaman).
Tidak ada glow.

## Gerak

Hanya keadaan tekan, transisi sheet, dan hitung mundur yang memang
menyampaikan informasi. Tidak ada fade up berantai, tidak ada elemen
melayang, tidak ada parallax. Gerak dipakai untuk mengarahkan perhatian
pada perubahan keadaan, bukan untuk mengisi halaman.

## Ikon

Web memakai Material Symbols Outlined, Flutter memakai varian rounded
bawaan Material. Ikon harus relevan dengan isinya. Kalau tidak ada ikon
yang pas, lebih baik tanpa ikon.

Dilarang sebagai hiasan: sparkle, bintang, petir, permata, robot.

## Bahasa

Bahasa Indonesia, kalimat pendek, tanpa jargon pemasaran. Tombol menyebut
tindakannya ("Tarik dana", "Jadikan rekening utama"), bukan "Mulai" atau
"Selengkapnya".

Pesan galat menyebutkan apa yang terjadi dan apa yang bisa dilakukan.
Tanpa tanda pisah em (—); pakai koma, titik, titik dua, atau tanda kurung.

## Aksesibilitas

Kontras minimal WCAG AA (4.5:1 teks biasa, 3:1 teks besar) diperiksa di
kedua tema. Status tidak pernah disampaikan hanya lewat warna atau ikon;
selalu ada teks berlabel. Target sentuh minimal 44px.
