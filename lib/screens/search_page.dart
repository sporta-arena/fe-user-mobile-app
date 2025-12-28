import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  final String keyword; // Kata kunci dari halaman Home

  const SearchPage({super.key, required this.keyword});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // --- DATA DUMMY (TAPI NYATA) ---
  // Di aplikasi asli, data ini diambil dari API Backend berdasarkan keyword
  final List<Map<String, dynamic>> _allVenues = [
    {
      "name": "Lafutsal Ciomas",
      "address": "Jl. Raya Laladon, Ciomas, Bogor",
      "price": "Rp 100.000",
      "rating": "4.5",
      "imageColor": Colors.green,
      "category": "Futsal",
      "distance": "1.2 km"
    },
    {
      "name": "GOR Hero Family Group",
      "address": "Kp Sawah Hilir, Ciomas, Bogor",
      "price": "Rp 35.000",
      "rating": "4.8",
      "imageColor": Colors.blue,
      "category": "Badminton & Futsal",
      "distance": "2.5 km"
    },
    {
      "name": "Inaka Futsal",
      "address": "Jl. Ciomas Harapan No.27, Bogor",
      "price": "Rp 80.000",
      "rating": "4.2",
      "imageColor": Colors.orange,
      "category": "Futsal",
      "distance": "3.0 km"
    },
    {
      "name": "Heis Futsal",
      "address": "Dramaga, Dekat IPB, Bogor",
      "price": "Rp 85.000",
      "rating": "4.4",
      "imageColor": Colors.redAccent,
      "category": "Futsal",
      "distance": "5.5 km"
    },
  ];

  late List<Map<String, dynamic>> _filteredVenues;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set awal pencarian sesuai keyword dari Home
    _searchController.text = widget.keyword;
    _filterVenues(widget.keyword);
  }

  void _filterVenues(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredVenues = _allVenues;
      } else {
        _filteredVenues = _allVenues
            .where((venue) =>
                venue['name'].toLowerCase().contains(query.toLowerCase()) ||
                venue['address'].toLowerCase().contains(query.toLowerCase()) ||
                venue['category'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // Search Bar di AppBar
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: _filterVenues, // Filter otomatis saat ngetik
            autofocus: false,
            decoration: const InputDecoration(
              hintText: "Cari lapangan...",
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ),
      body: _filteredVenues.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredVenues.length,
              itemBuilder: (context, index) {
                final venue = _filteredVenues[index];
                return _buildSearchResultCard(venue);
              },
            ),
    );
  }

  // --- WIDGET CARD HASIL PENCARIAN ---
  Widget _buildSearchResultCard(Map<String, dynamic> venue) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Membuka ${venue['name']}...")));
        // Nanti di sini navigasi ke DetailPage(venue)
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Kecil di Kiri
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: venue['imageColor'],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: const Center(
                  child: Icon(Icons.sports_soccer, color: Colors.white, size: 40)),
            ),
            
            // Info di Kanan
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kategori & Jarak
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(venue['category'], style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        ),
                        Text("${venue['distance']}", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Nama Venue
                    Text(
                      venue['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    // Alamat
                    Text(
                      venue['address'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    
                    // Harga & Rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          venue['price'],
                          style: const TextStyle(
                              color: Color(0xFF0047FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.orange),
                            const SizedBox(width: 2),
                            Text(venue['rating'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET JIKA TIDAK DITEMUKAN ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Tidak ditemukan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          Text("Coba kata kunci lain", style: TextStyle(color: Colors.grey[400])),
        ],
      ),
    );
  }
}