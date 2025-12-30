import 'package:flutter/material.dart';
import 'payment_processing_page.dart'; // Import halaman payment processing

class BookingConfirmationPage extends StatefulWidget {
  final String venueName;
  final String selectedDate; // Format: YYYY-MM-DD
  final String selectedTime;
  final int price;

  const BookingConfirmationPage({
    super.key,
    required this.venueName,
    required this.selectedDate,
    required this.selectedTime,
    required this.price,
  });

  @override
  State<BookingConfirmationPage> createState() => _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  // Controllers untuk form input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // State untuk Metode Pembayaran
  int _selectedPaymentMethod = 0;
  
  // Daftar metode pembayaran dengan fee yang realistis sesuai Xendit
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 0,
      'title': 'QRIS (Gopay, OVO, Dana, ShopeePay)',
      'subtitle': 'Scan QR Code untuk bayar',
      'icon': Icons.qr_code_scanner,
      'fee': 1500, // Flat fee QRIS
      'feeType': 'flat'
    },
    {
      'id': 1,
      'title': 'Virtual Account BCA',
      'subtitle': 'Transfer ke VA BCA',
      'icon': Icons.account_balance,
      'fee': 4000, // Fee VA BCA
      'feeType': 'flat'
    },
    {
      'id': 2,
      'title': 'Virtual Account BNI',
      'subtitle': 'Transfer ke VA BNI',
      'icon': Icons.account_balance,
      'fee': 4000, // Fee VA BNI
      'feeType': 'flat'
    },
    {
      'id': 3,
      'title': 'Virtual Account BRI',
      'subtitle': 'Transfer ke VA BRI',
      'icon': Icons.account_balance,
      'fee': 4000, // Fee VA BRI
      'feeType': 'flat'
    },
    {
      'id': 4,
      'title': 'Virtual Account Mandiri',
      'subtitle': 'Transfer ke VA Mandiri',
      'icon': Icons.account_balance,
      'fee': 4000, // Fee VA Mandiri
      'feeType': 'flat'
    },
    {
      'id': 5,
      'title': 'Virtual Account Permata',
      'subtitle': 'Transfer ke VA Permata',
      'icon': Icons.account_balance,
      'fee': 4000, // Fee VA Permata
      'feeType': 'flat'
    },
    {
      'id': 6,
      'title': 'Alfamart',
      'subtitle': 'Bayar di counter Alfamart',
      'icon': Icons.store,
      'fee': 2500, // Fee Alfamart
      'feeType': 'flat'
    },
    {
      'id': 7,
      'title': 'Indomaret',
      'subtitle': 'Bayar di counter Indomaret',
      'icon': Icons.store,
      'fee': 2500, // Fee Indomaret
      'feeType': 'flat'
    },
    {
      'id': 8,
      'title': 'Credit Card (Visa/Mastercard)',
      'subtitle': 'Bayar dengan kartu kredit',
      'icon': Icons.credit_card,
      'fee': 0, // Fee percentage akan dihitung
      'feeType': 'percentage',
      'feePercentage': 2.9 // 2.9% + Rp 2000
    },
  ];
  
  @override
  void initState() {
    super.initState();
    // Pre-fill dengan data user yang sudah login
    _nameController.text = ""; // Kosong biar user isi sendiri
    _phoneController.text = "081234567890"; // Dari data registrasi
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  // Fungsi untuk menghitung fee berdasarkan metode pembayaran
  int _calculatePaymentFee() {
    final selectedMethod = _paymentMethods[_selectedPaymentMethod];
    
    if (selectedMethod['feeType'] == 'flat') {
      return selectedMethod['fee'];
    } else if (selectedMethod['feeType'] == 'percentage') {
      // Credit card: 2.9% + Rp 2000
      double percentageFee = widget.price.toDouble() * (selectedMethod['feePercentage'] / 100);
      return (percentageFee + 2000).round();
    }
    
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Hitung Total dengan fee dinamis
    int paymentFee = _calculatePaymentFee();
    int totalPayment = widget.price + paymentFee;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Konfirmasi Booking", 
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. RINGKASAN JADWAL ---
            const Text(
              "Jadwal Main", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05), 
                    blurRadius: 10, 
                    offset: const Offset(0, 4)
                  )
                ],
              ),
              child: Row(
                children: [
                  // Icon Kalender Besar
                  Container(
                    height: 60, 
                    width: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F5FF), 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: const Icon(
                      Icons.calendar_month, 
                      color: Color(0xFF0047FF), 
                      size: 30
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.venueName, 
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16
                          )
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${widget.selectedDate} • Jam ${widget.selectedTime}", 
                          style: TextStyle(color: Colors.grey[600])
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 2. DATA PEMESAN ---
            const Text(
              "Data Pemesan", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16)
              ),
              child: Column(
                children: [
                  _buildEditableTextField("Nama Lengkap", _nameController, "Masukkan nama lengkap"),
                  const SizedBox(height: 16),
                  _buildEditableTextField("Nomor WhatsApp", _phoneController, "Contoh: 081234567890"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 3. METODE PEMBAYARAN ---
            const Text(
              "Metode Pembayaran", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            const SizedBox(height: 12),
            // Tampilkan semua metode pembayaran
            ..._paymentMethods.map((method) => _buildPaymentOption(
              method['id'], 
              method['title'], 
              method['subtitle'],
              method['icon']
            )).toList(),

            const SizedBox(height: 24),

            // --- 4. RINCIAN HARGA ---
            const Text(
              "Rincian Pembayaran", 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16)
              ),
              child: Column(
                children: [
                  _buildPriceRow("Harga Sewa", widget.price),
                  const SizedBox(height: 8),
                  _buildPriceRow("Biaya Payment", paymentFee),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total Pembayaran", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      Text(
                        _formatCurrency(totalPayment),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900, 
                          fontSize: 18, 
                          color: Color(0xFF0047FF)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100), // Space untuk bottom bar
          ],
        ),
      ),

      // --- BOTTOM BAR ---
      bottomNavigationBar: Container(
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
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Validasi form
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Nama lengkap harus diisi!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (_phoneController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Nomor WhatsApp harus diisi!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Aksi Bayar -> Pindah ke Halaman Payment Processing
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentProcessingPage(
                      venueName: widget.venueName,
                      selectedDate: widget.selectedDate,
                      selectedTime: widget.selectedTime,
                      price: widget.price,
                      paymentMethodId: _selectedPaymentMethod,
                      customerName: _nameController.text.trim(),
                      customerPhone: _phoneController.text.trim(),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0047FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)
                ),
              ),
              child: const Text(
                "BAYAR SEKARANG", 
                style: TextStyle(
                  color: Colors.white, 
                  fontWeight: FontWeight.bold, 
                  fontSize: 16
                )
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildEditableTextField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label, 
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF0047FF)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          keyboardType: label.contains("WhatsApp") ? TextInputType.phone : TextInputType.name,
        ),
      ],
    );
  }

  Widget _buildPaymentOption(int index, String title, String subtitle, IconData icon) {
    bool isSelected = _selectedPaymentMethod == index;
    final method = _paymentMethods[index];
    
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0047FF) : Colors.grey.shade200, 
            width: isSelected ? 2 : 1
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02), 
              blurRadius: 5
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  icon, 
                  color: isSelected ? const Color(0xFF0047FF) : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title, 
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 14,
                        )
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected) 
                  const Icon(Icons.check_circle, color: Color(0xFF0047FF)),
              ],
            ),
            
            // Tampilkan info fee
            if (isSelected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0047FF).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFF0047FF)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        method['feeType'] == 'flat' 
                          ? "Biaya payment: ${_formatCurrency(method['fee'])}"
                          : "Biaya payment: ${method['feePercentage']}% + Rp 2.000 = ${_formatCurrency(_calculatePaymentFee())}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0047FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: TextStyle(color: Colors.grey[600])
        ),
        Text(
          _formatCurrency(amount), 
          style: const TextStyle(fontWeight: FontWeight.w500)
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]}.'
    )}";
  }
}