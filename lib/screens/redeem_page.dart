import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class RedeemPage extends StatefulWidget {
  final int currentPoints; // Menerima data poin dari Halaman Gacha

  const RedeemPage({super.key, required this.currentPoints});

  @override
  State<RedeemPage> createState() => _RedeemPageState();
}

class _RedeemPageState extends State<RedeemPage> {
  late int _myPoints; // Variabel lokal untuk menyimpan sisa poin

  @override
  void initState() {
    super.initState();
    _myPoints = widget.currentPoints; // Ambil poin yang dikirim
  }

  // --- KATALOG HADIAH OLAHRAGA ---
  final List<Map<String, dynamic>> _catalog = [
    {
      "name": "Jersey Sportago Premium",
      "price": 2500,
      "icon": Icons.checkroom, // Ikon Baju
      "color": Colors.blueAccent,
      "desc": "Bahan Dry-Fit adem"
    },
    {
      "name": "Bola Futsal Pro",
      "price": 1500,
      "icon": Icons.sports_soccer,
      "color": Colors.white, // Nanti dikasih background gelap
      "desc": "Standar FIFA"
    },
    {
      "name": "Kacamata Renang",
      "price": 800,
      "icon": Icons.visibility, // Ikon Mata/Kacamata
      "color": Colors.cyan,
      "desc": "Anti-Fog Lens"
    },
    {
      "name": "Botol Minum Sport",
      "price": 500,
      "icon": Icons.local_drink,
      "color": Colors.green,
      "desc": "BPA Free 1 Liter"
    },
    {
      "name": "Kaos Kaki Anti-Slip",
      "price": 300,
      "icon": Icons.accessibility_new, // Ikon Kaki
      "color": Colors.orange,
      "desc": "Nyaman dipakai main"
    },
    {
      "name": "Voucher Sewa 1 Jam",
      "price": 1000,
      "icon": Icons.confirmation_number,
      "color": Colors.purple,
      "desc": "Berlaku semua venue"
    },
  ];

  // --- FUNGSI REDEEM (CLAIM) ---
  void _claimReward(String itemName, int price) {
    if (_myPoints >= price) {
      // 1. Kurangi Poin Lokal
      setState(() {
        _myPoints -= price;
      });

      // 2. Tampilkan Popup Sukses
      showDialog(
        context: context,
        barrierDismissible: false, // User harus klik tombol OK
        builder: (ctx) => AlertDialog(
          backgroundColor: context.c.raised,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: context.c.ok, size: 60),
              const SizedBox(height: 16),
              Text(
                "Redeem Berhasil!",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.c.ink)
              ),
              const SizedBox(height: 8),
              Text(
                "Kamu berhasil menukar $itemName.\nSisa Poin: $_myPoints",
                textAlign: TextAlign.center,
                style: TextStyle(color: context.c.inkSoft),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.c.accent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "OK, MANTAP",
                  style: TextStyle(color: context.c.onAccent, fontWeight: FontWeight.w700)
                ),
              )
            ],
          ),
        ),
      );
    } else {
      // Poin Kurang
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Poin kamu belum cukup untuk item ini!"),
          backgroundColor: context.c.danger,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // Fungsi tombol Back (Pojok Kiri Atas)
  void _onBack() {
    // Kembalikan sisa poin terbaru ke halaman sebelumnya (Loyalty Page)
    Navigator.pop(context, _myPoints);
  }

  @override
  Widget build(BuildContext context) {
    // Intercept tombol back fisik (Android) agar tetap update poin
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: context.c.surface,
        appBar: AppBar(
          systemOverlayStyle: gayaOverlay(context),
          title: Text(
            "Tukar Poin",
            style: TextStyle(color: context.c.ink, fontWeight: FontWeight.bold)
          ),
          backgroundColor: context.c.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: context.c.ink),
            onPressed: _onBack, // Panggil fungsi custom back
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: context.c.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.stars, color: context.c.accent, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    "$_myPoints pts",
                    style: TextStyle(
                      color: context.c.accent,
                      fontWeight: FontWeight.w900
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 Kolom
            childAspectRatio: 0.7, // Aspek rasio kartu (Tinggi)
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _catalog.length,
          itemBuilder: (context, index) {
            final item = _catalog[index];
            final bool canAfford = _myPoints >= item['price'];

            return Container(
              decoration: BoxDecoration(
                color: context.c.raised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Gambar Barang
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        color: (item['color'] as Color).withValues(alpha: 0.15),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Center(
                        child: Icon(
                          item['icon'], 
                          size: 60, 
                          color: item['color']
                        ),
                      ),
                    ),
                  ),

                  // 2. Info Barang
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: context.c.ink
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['desc'],
                            style: TextStyle(
                              fontSize: 10,
                              color: context.c.inkSoft
                            )
                          ),
                          const Spacer(),
                          Text(
                            "${item['price']} Poin",
                            style: TextStyle(
                              color: context.c.accent,
                              fontWeight: FontWeight.w900,
                              fontSize: 16
                            )
                          ),
                          const SizedBox(height: 8),

                          // 3. Tombol Claim
                          SizedBox(
                            width: double.infinity,
                            height: 36,
                            child: ElevatedButton(
                              onPressed: canAfford 
                                ? () => _claimReward(item['name'], item['price']) 
                                : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.c.accent,
                                disabledBackgroundColor: context.c.line,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999)
                                ),
                              ),
                              child: Text(
                                canAfford ? "CLAIM" : "POIN KURANG",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: canAfford ? context.c.onAccent : context.c.inkSoft
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}