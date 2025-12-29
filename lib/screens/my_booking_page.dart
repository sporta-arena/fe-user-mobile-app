import 'package:flutter/material.dart';

class MyBookingPage extends StatefulWidget {
  const MyBookingPage({super.key});

  @override
  State<MyBookingPage> createState() => _MyBookingPageState();
}

class _MyBookingPageState extends State<MyBookingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Data dummy booking
  final List<Map<String, dynamic>> _upcomingBookings = [
    {
      'id': 'SPT-882910',
      'venueName': 'Gor Futsal Champions',
      'location': 'Kemang, Jakarta Selatan',
      'date': '2024-01-15',
      'time': '19:00 - 20:00',
      'price': 150000,
      'status': 'confirmed',
      'category': 'Futsal',
      'imageColor': Colors.green,
    },
    {
      'id': 'SPT-882911',
      'venueName': 'Badminton Arena Pro',
      'location': 'Tebet, Jakarta Selatan',
      'date': '2024-01-18',
      'time': '08:00 - 09:00',
      'price': 60000,
      'status': 'confirmed',
      'category': 'Badminton',
      'imageColor': Colors.blue,
    },
  ];

  final List<Map<String, dynamic>> _pastBookings = [
    {
      'id': 'SPT-882908',
      'venueName': 'Basketball Hall A',
      'location': 'Senayan, Jakarta Pusat',
      'date': '2024-01-10',
      'time': '16:00 - 17:00',
      'price': 200000,
      'status': 'completed',
      'category': 'Basketball',
      'imageColor': Colors.orange,
      'rating': 5,
    },
    {
      'id': 'SPT-882907',
      'venueName': 'Tennis Court Premium',
      'location': 'Menteng, Jakarta Pusat',
      'date': '2024-01-05',
      'time': '10:00 - 11:00',
      'price': 120000,
      'status': 'completed',
      'category': 'Tennis',
      'imageColor': Colors.purple,
      'rating': 4,
    },
  ];

  final List<Map<String, dynamic>> _cancelledBookings = [
    {
      'id': 'SPT-882906',
      'venueName': 'Swimming Pool Deluxe',
      'location': 'Pancoran, Jakarta Selatan',
      'date': '2024-01-12',
      'time': '14:00 - 15:00',
      'price': 80000,
      'status': 'cancelled',
      'category': 'Swimming',
      'imageColor': Colors.cyan,
      'cancelReason': 'Dibatalkan oleh pengguna',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "My Booking",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0047FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0047FF),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Upcoming"),
            Tab(text: "Past"),
            Tab(text: "Cancelled"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingTab(),
          _buildPastTab(),
          _buildCancelledTab(),
        ],
      ),
    );
  }

  // Tab Upcoming Bookings
  Widget _buildUpcomingTab() {
    if (_upcomingBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available,
        title: "Belum Ada Booking",
        subtitle: "Booking lapangan favoritmu sekarang!",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _upcomingBookings.length,
      itemBuilder: (context, index) {
        final booking = _upcomingBookings[index];
        return _buildUpcomingBookingCard(booking);
      },
    );
  }

  // Tab Past Bookings
  Widget _buildPastTab() {
    if (_pastBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: "Belum Ada Riwayat",
        subtitle: "Riwayat booking akan muncul di sini",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pastBookings.length,
      itemBuilder: (context, index) {
        final booking = _pastBookings[index];
        return _buildPastBookingCard(booking);
      },
    );
  }

  // Tab Cancelled Bookings
  Widget _buildCancelledTab() {
    if (_cancelledBookings.isEmpty) {
      return _buildEmptyState(
        icon: Icons.cancel_outlined,
        title: "Tidak Ada Pembatalan",
        subtitle: "Semua booking berjalan lancar!",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _cancelledBookings.length,
      itemBuilder: (context, index) {
        final booking = _cancelledBookings[index];
        return _buildCancelledBookingCard(booking);
      },
    );
  }

  // Empty State Widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Upcoming Booking Card
  Widget _buildUpcomingBookingCard(Map<String, dynamic> booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header dengan status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0047FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Booking ID: ${booking['id']}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "CONFIRMED",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Venue Image Placeholder
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: booking['imageColor'].withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.sports,
                        color: booking['imageColor'],
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Venue Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking['venueName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking['location'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0047FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              booking['category'],
                              style: const TextStyle(
                                color: Color(0xFF0047FF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Date, Time, Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tanggal & Waktu",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${booking['date']} • ${booking['time']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Total Bayar",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(booking['price']),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0047FF),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _showCancelDialog(booking['id']);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _showBookingDetails(booking);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0047FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "View Details",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Past Booking Card
  Widget _buildPastBookingCard(Map<String, dynamic> booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Venue Image Placeholder
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: booking['imageColor'].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.sports,
                    color: booking['imageColor'],
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),

                // Venue Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['venueName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${booking['date']} • ${booking['time']}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      "${booking['rating']}.0",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatCurrency(booking['price']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0047FF),
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        _showBookingDetails(booking);
                      },
                      child: const Text("View Details"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showBookAgainDialog(booking);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0047FF),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Book Again",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Cancelled Booking Card
  Widget _buildCancelledBookingCard(Map<String, dynamic> booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Venue Image Placeholder (Greyed out)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.sports,
                    color: Colors.grey,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),

                // Venue Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['venueName'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${booking['date']} • ${booking['time']}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Cancelled Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "CANCELLED",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking['cancelReason'],
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Functions
  String _formatCurrency(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    )}";
  }

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Booking"),
        content: const Text("Are you sure you want to cancel this booking?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Booking $bookingId cancelled")),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Booking Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ID: ${booking['id']}"),
            Text("Venue: ${booking['venueName']}"),
            Text("Date: ${booking['date']}"),
            Text("Time: ${booking['time']}"),
            Text("Price: ${_formatCurrency(booking['price'])}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showBookAgainDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Book Again"),
        content: Text("Book ${booking['venueName']} again?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Redirecting to booking page...")),
              );
            },
            child: const Text("Book Now"),
          ),
        ],
      ),
    );
  }
}