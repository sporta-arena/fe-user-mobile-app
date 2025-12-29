import 'package:flutter/material.dart';
import 'booking_confirmation_page.dart';

class VenueDetailPage extends StatefulWidget {
  // Di aplikasi nyata, kamu akan menerima ID venue di sini
  // final String venueId;
  // const VenueDetailPage({super.key, required this.venueId});
  
  const VenueDetailPage({super.key});

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  // --- STATE VARIABLES ---
  DateTime _selectedDate = DateTime.now(); // Tanggal yang dipilih (default hari ini)
  String? _selectedTimeSlot; // Jam yang dipilih user (baru bisa pilih 1 jam dulu)
  int _currentImageIndex = 0; // Untuk indikator slider foto

  // --- DATA DUMMY VENUE ---
  final String _venueName = "Gor Futsal Champions";
  final int _pricePerHour = 150000;
  final double _rating = 4.8;
  final String _address = "Jl. Kemang Raya No. 10, Jakarta Selatan";
  final String _description = "Lapangan futsal standar internasional dengan rumput sintetis kualitas terbaik. Dilengkapi lampu LED terang untuk main malam, tribun penonton, dan ventilasi udara yang baik.";
  final List<String> _facilities = ["Parkir Luas", "Kamar Mandi", "Locker", "Kantin", "Mushola", "Wifi"];
  final List<Color> _photoColors = [Colors.blue, Colors.green, Colors.orange]; // Placeholder foto

  // --- DATA DUMMY JADWAL (BOOKED SLOTS) ---
  // Format Key: YYYY-MM-DD (Penting agar mudah dibandingkan)
  final Map<String, List<String>> _bookedSlotsDb = {
    // Contoh: Hari ini (ubah tanggalnya sesuai hari kamu testing jika perlu)
    DateTime.now().toString().split(' ')[0]: ['08:00', '09:00', '18:00', '19:00', '20:00', '21:00'],
    // Contoh: Besok
    DateTime.now().add(const Duration(days: 1)).toString().split(' ')[0]: ['10:00', '11:00', '12:00'],
  };

  // Daftar jam operasional (misal buka jam 8 pagi sampai 10 malam)
  final List<String> _allTimeSlots = List.generate(15, (index) {
    int hour = 8 + index; // Mulai jam 8
    return "${hour.toString().padLeft(2, '0')}:00"; // Format 08:00, 09:00, dst
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Bottom Bar untuk tombol Booking
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // 1. APP BAR & IMAGE SLIDER (SliverAppBar)
            _buildSliverAppBar(),
            
            // 2. KONTEN BODY
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Info (Nama, Rating, Alamat)
                    _buildHeaderInfo(),
                    const SizedBox(height: 24),
                    
                    // Deskripsi & Fasilitas
                    _buildDescriptionSection(),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 20),
                    
                    // --- SECTION BOOKING ---
                    const Text("Pilih Jadwal Main", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    // 3. DATE PICKER (H+7)
                    Text("Tanggal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    const SizedBox(height: 12),
                    _buildDatePicker(),
                    const SizedBox(height: 24),
                    
                    // 4. TIME SLOT PICKER (Grid)
                    Text("Jam Tersedia", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    const SizedBox(height: 12),
                    _buildTimeSlotGrid(),
                    const SizedBox(height: 100), // Jarak agar tidak ketutup bottom bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= WIDGET BUILDERS =================

  // 1. Sliver App Bar (Foto & Back Button)
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true, // Agar appbar tetap nempel saat discroll
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5), 
          shape: BoxShape.circle
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5), 
            shape: BoxShape.circle
          ),
          child: IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.red), 
            onPressed: () {}
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // PageView untuk Slider Foto
            PageView.builder(
              itemCount: _photoColors.length,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemBuilder: (context, index) {
                return Container(
                  color: _photoColors[index], // Placeholder warna
                  child: const Center(
                    child: Icon(Icons.image, size: 100, color: Colors.white54)
                  ),
                  // Nanti ganti dengan Image.network(url)
                );
              },
            ),
            
            // Indikator Titik-titik
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_photoColors.length, (index) => 
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8, 
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index ? Colors.white : Colors.white54,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // 2. Header Info (Judul, dll)
  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _venueName, 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(12)
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 16), 
                  const SizedBox(width: 4), 
                  Text(
                    _rating.toString(), 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)
                  )
                ]
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _address, 
                style: TextStyle(color: Colors.grey[600])
              )
            ),
          ],
        ),
      ],
    );
  }

  // 3. Deskripsi & Fasilitas
  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tentang Arena", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text(
          _description, 
          style: TextStyle(color: Colors.grey[700], height: 1.5)
        ),
        const SizedBox(height: 20),
        const Text("Fasilitas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10, 
          runSpacing: 10,
          children: _facilities.map((facility) => 
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100], 
                borderRadius: BorderRadius.circular(8), 
                border: Border.all(color: Colors.grey.shade200)
              ),
              child: Text(
                facility, 
                style: TextStyle(color: Colors.grey[800], fontSize: 12)
              ),
            )
          ).toList(),
        ),
      ],
    );
  }

  // 4. Date Picker (H+7 Horizontal)
  Widget _buildDatePicker() {
    // Helper sederhana untuk nama hari (bisa pakai package intl kalau mau lebih proper)
    List<String> dayNames = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];
    
    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7, // 7 Hari ke depan
        itemBuilder: (context, index) {
          // Hitung tanggal untuk index ini
          DateTime date = DateTime.now().add(Duration(days: index));
          
          // Cek apakah ini tanggal yang sedang dipilih
          bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
          
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _selectedTimeSlot = null; // Reset pilihan jam jika tanggal berubah
              });
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0047FF) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0047FF) : Colors.grey.shade300
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF0047FF).withOpacity(0.3), 
                    blurRadius: 8, 
                    offset: const Offset(0,4)
                  )
                ] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNames[date.weekday - 1], 
                    style: TextStyle(
                      fontSize: 14, 
                      color: isSelected ? Colors.white : Colors.grey
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(), 
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: isSelected ? Colors.white : Colors.black
                    )
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 5. Time Slot Grid (LOGIKA UTAMA DI SINI)
  Widget _buildTimeSlotGrid() {
    // A. Dapatkan Key Tanggal yang dipilih (Format YYYY-MM-DD)
    String dateKey = _selectedDate.toString().split(' ')[0];
    
    // B. Ambil daftar jam yang sudah dibooking pada tanggal tersebut dari DB dummy
    List<String> bookedToday = _bookedSlotsDb[dateKey] ?? [];
    
    return GridView.builder(
      shrinkWrap: true, // Agar tidak error di dalam ScrollView
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, // 4 kolom per baris
        childAspectRatio: 1.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _allTimeSlots.length,
      itemBuilder: (context, index) {
        String slot = _allTimeSlots[index];
        
        // C. LOGIKA PENENTUAN STATUS SLOT
        bool isBooked = bookedToday.contains(slot); // Cek apakah ada di daftar booked
        bool isSelected = slot == _selectedTimeSlot; // Cek apakah sedang diklik user
        
        // Tentukan Warna & Style berdasarkan status
        Color bgColor;
        Color textColor;
        Color borderColor;
        
        if (isBooked) {
          // STATUS: BOOKED (Disable)
          bgColor = Colors.grey[200]!;
          textColor = Colors.grey[400]!;
          borderColor = Colors.transparent;
        } else if (isSelected) {
          // STATUS: SELECTED (Aktif)
          bgColor = const Color(0xFF0047FF);
          textColor = Colors.white;
          borderColor = const Color(0xFF0047FF);
        } else {
          // STATUS: AVAILABLE (Bisa dipilih)
          bgColor = Colors.white;
          textColor = Colors.black87;
          borderColor = Colors.grey.shade300;
        }
        
        return GestureDetector(
          onTap: isBooked ? null : () { // Jika booked, tombol tidak bisa diklik (null)
            setState(() {
              // Toggle selection: kalau diklik lagi, jadi unselected
              if (_selectedTimeSlot == slot) {
                _selectedTimeSlot = null;
              } else {
                _selectedTimeSlot = slot;
              }
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            // Jika booked, coret teksnya
            child: Text(
              slot, 
              style: TextStyle(
                color: textColor, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                decoration: isBooked ? TextDecoration.lineThrough : null,
              )
            ),
          ),
        );
      },
    );
  }

  // 6. Bottom Navigation Bar (Sticky Price & Button)
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), 
            blurRadius: 10, 
            offset: const Offset(0, -5)
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Harga", 
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)
                  ),
                  // Tampilkan harga atau 0 jika belum pilih jam
                  Text(
                    _selectedTimeSlot == null 
                      ? "Rp 0" 
                      : "Rp ${_pricePerHour.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}", // Format Ribuan sederhana
                    style: const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.w900, 
                      color: Color(0xFF0047FF)
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            
            // Tombol Booking
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedTimeSlot == null ? null : () {
                  // --- UBAH DARI SINI ---
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingConfirmationPage(
                        venueName: _venueName,          // Kirim Nama Venue
                        selectedDate: _selectedDate.toString().split(' ')[0], // Kirim Tanggal (String YYYY-MM-DD)
                        selectedTime: _selectedTimeSlot!, // Kirim Jam
                        price: _pricePerHour,           // Kirim Harga (int)
                      ),
                    ),
                  );
                  // ---------------------
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0047FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  // Disable warna kalau belum pilih jam
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  "BOOKING SEKARANG", 
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}