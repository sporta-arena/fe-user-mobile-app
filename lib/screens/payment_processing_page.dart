import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/xendit_service.dart';
import 'booking_success_page.dart';
import 'dart:math' as math;

// Custom painter untuk QR Code visual
class QRCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final blockSize = size.width / 25; // 25x25 grid
    final random = math.Random(42); // Fixed seed untuk konsistensi

    // Draw QR code pattern
    for (int i = 0; i < 25; i++) {
      for (int j = 0; j < 25; j++) {
        // Corner squares (finder patterns)
        if ((i < 7 && j < 7) || 
            (i < 7 && j > 17) || 
            (i > 17 && j < 7)) {
          if ((i == 0 || i == 6 || j == 0 || j == 6) ||
              (i >= 2 && i <= 4 && j >= 2 && j <= 4)) {
            canvas.drawRect(
              Rect.fromLTWH(j * blockSize, i * blockSize, blockSize, blockSize),
              paint,
            );
          }
        }
        // Random pattern for data
        else if (i > 8 && j > 8 && i < 17 && j < 17) {
          if (random.nextBool()) {
            canvas.drawRect(
              Rect.fromLTWH(j * blockSize, i * blockSize, blockSize, blockSize),
              paint,
            );
          }
        }
        // Timing patterns
        else if (i == 6 || j == 6) {
          if ((i + j) % 2 == 0) {
            canvas.drawRect(
              Rect.fromLTWH(j * blockSize, i * blockSize, blockSize, blockSize),
              paint,
            );
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PaymentProcessingPage extends StatefulWidget {
  final String venueName;
  final String selectedDate;
  final String selectedTime;
  final int price;
  final int paymentMethodId;
  final String customerName;
  final String customerPhone;

  const PaymentProcessingPage({
    super.key,
    required this.venueName,
    required this.selectedDate,
    required this.selectedTime,
    required this.price,
    required this.paymentMethodId,
    required this.customerName,
    required this.customerPhone,
  });

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends State<PaymentProcessingPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic>? _paymentData;
  String _paymentType = '';

  // Payment method mapping
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 0,
      'title': 'QRIS (Gopay, OVO, Dana, ShopeePay)',
      'type': 'qris',
      'fee': 1500,
    },
    {
      'id': 1,
      'title': 'Virtual Account BCA',
      'type': 'va',
      'bankCode': 'BCA',
      'fee': 4000,
    },
    {
      'id': 2,
      'title': 'Virtual Account BNI',
      'type': 'va',
      'bankCode': 'BNI',
      'fee': 4000,
    },
    {
      'id': 3,
      'title': 'Virtual Account BRI',
      'type': 'va',
      'bankCode': 'BRI',
      'fee': 4000,
    },
    {
      'id': 4,
      'title': 'Virtual Account Mandiri',
      'type': 'va',
      'bankCode': 'MANDIRI',
      'fee': 4000,
    },
    {
      'id': 5,
      'title': 'Virtual Account Permata',
      'type': 'va',
      'bankCode': 'PERMATA',
      'fee': 4000,
    },
    {
      'id': 6,
      'title': 'Alfamart',
      'type': 'retail',
      'retailCode': 'ALFAMART',
      'fee': 2500,
    },
    {
      'id': 7,
      'title': 'Indomaret',
      'type': 'retail',
      'retailCode': 'INDOMARET',
      'fee': 2500,
    },
    {
      'id': 8,
      'title': 'Credit Card (Visa/Mastercard)',
      'type': 'credit_card',
      'fee': 0, // Will be calculated
    },
  ];

  @override
  void initState() {
    super.initState();
    _createPayment();
  }

  Future<void> _createPayment() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final selectedMethod = _paymentMethods[widget.paymentMethodId];
      _paymentType = selectedMethod['type'];
      
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Create mock payment data for development
      Map<String, dynamic> result = _createMockPaymentData(selectedMethod);

      setState(() {
        _paymentData = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _createMockPaymentData(Map<String, dynamic> method) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    
    switch (method['type']) {
      case 'qris':
        return {
          'id': 'qr_$timestamp',
          'qr_string': 'mock_qr_string_for_development',
          'status': 'ACTIVE',
        };
        
      case 'va':
        return {
          'id': 'va_$timestamp',
          'account_number': '${method['bankCode'] == 'BCA' ? '70012' : '88810'}${timestamp.substring(7)}',
          'bank_code': method['bankCode'],
          'status': 'ACTIVE',
        };
        
      case 'retail':
        return {
          'id': 'retail_$timestamp',
          'payment_code': timestamp.substring(7),
          'retail_outlet_name': method['retailCode'],
          'status': 'ACTIVE',
        };
        
      case 'credit_card':
        return {
          'id': 'invoice_$timestamp',
          'invoice_url': 'https://checkout.xendit.co/web/$timestamp',
          'status': 'PENDING',
        };
        
      default:
        return {'id': 'mock_$timestamp', 'status': 'ACTIVE'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Payment",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _hasError
              ? _buildErrorState()
              : _buildPaymentInstructions(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF0047FF)),
          SizedBox(height: 20),
          Text(
            "Membuat pembayaran...",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              "Pembayaran Gagal",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _createPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0047FF),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text(
                "Coba Lagi",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    switch (_paymentType) {
      case 'qris':
        return _buildQRISInstructions();
      case 'va':
        return _buildVAInstructions();
      case 'retail':
        return _buildRetailInstructions();
      case 'credit_card':
        return _buildCreditCardInstructions();
      default:
        return const Center(child: Text("Payment method not supported"));
    }
  }

  Widget _buildQRISInstructions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // QR Code Display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Scan QR Code untuk Bayar",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // QR Code placeholder dengan pattern yang lebih realistis
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CustomPaint(
                    painter: QRCodePainter(),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 160),
                          Text(
                            "SCAN ME", 
                            style: TextStyle(
                              color: Colors.black87, 
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                Text(
                  "Total: ${XenditService.formatCurrency(widget.price + (_paymentMethods[0]['fee'] as int))}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0047FF),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Instructions
          _buildInstructionCard([
            "1. Buka aplikasi Gopay, OVO, Dana, atau ShopeePay",
            "2. Pilih menu Scan QR atau Bayar",
            "3. Scan QR Code di atas",
            "4. Konfirmasi pembayaran",
            "5. Pembayaran akan otomatis terverifikasi",
          ]),

          const SizedBox(height: 30),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _simulatePaymentSuccess(),
                  child: const Text("Simulasi Bayar"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _checkPaymentStatus(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0047FF),
                  ),
                  child: const Text(
                    "Cek Status",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVAInstructions() {
    final vaNumber = _paymentData?['account_number'] ?? 'Loading...';
    final bankName = _paymentMethods[widget.paymentMethodId]['title'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // VA Number Display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  bankName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                const Text("Nomor Virtual Account:", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        vaNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyToClipboard(vaNumber),
                        icon: const Icon(Icons.copy, color: Color(0xFF0047FF)),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                Text(
                  "Total: ${XenditService.formatCurrency(widget.price + (_paymentMethods[widget.paymentMethodId]['fee'] as int))}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0047FF),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Instructions
          _buildInstructionCard([
            "1. Buka aplikasi mobile banking atau ATM",
            "2. Pilih menu Transfer",
            "3. Pilih Transfer ke Virtual Account",
            "4. Masukkan nomor VA di atas",
            "5. Masukkan nominal sesuai total pembayaran",
            "6. Konfirmasi transfer",
          ]),

          const SizedBox(height: 30),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _simulatePaymentSuccess(),
                  child: const Text("Simulasi Bayar"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _checkPaymentStatus(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0047FF),
                  ),
                  child: const Text(
                    "Cek Status",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRetailInstructions() {
    final paymentCode = _paymentData?['payment_code'] ?? 'Loading...';
    final retailName = _paymentMethods[widget.paymentMethodId]['title'];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Payment Code Display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  "Bayar di $retailName",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                const Text("Kode Pembayaran:", style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        paymentCode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _copyToClipboard(paymentCode),
                        icon: const Icon(Icons.copy, color: Color(0xFF0047FF)),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                Text(
                  "Total: ${XenditService.formatCurrency(widget.price + (_paymentMethods[widget.paymentMethodId]['fee'] as int))}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0047FF),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Instructions
          _buildInstructionCard([
            "1. Kunjungi outlet $retailName terdekat",
            "2. Berikan kode pembayaran ke kasir",
            "3. Bayar sesuai nominal yang tertera",
            "4. Simpan struk sebagai bukti pembayaran",
            "5. Pembayaran akan otomatis terverifikasi",
          ]),

          const SizedBox(height: 30),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _simulatePaymentSuccess(),
                  child: const Text("Simulasi Bayar"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _checkPaymentStatus(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0047FF),
                  ),
                  child: const Text(
                    "Cek Status",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardInstructions() {
    final invoiceUrl = _paymentData?['invoice_url'] ?? '';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Credit Card Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "Pembayaran Kartu Kredit",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                const Icon(Icons.credit_card, size: 80, color: Color(0xFF0047FF)),
                
                const SizedBox(height: 20),
                Text(
                  "Total: ${XenditService.formatCurrency(_calculateCreditCardFee())}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0047FF),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Instructions
          _buildInstructionCard([
            "1. Klik tombol 'Bayar dengan Kartu Kredit'",
            "2. Anda akan diarahkan ke halaman pembayaran",
            "3. Masukkan detail kartu kredit Anda",
            "4. Konfirmasi pembayaran",
            "5. Tunggu konfirmasi dari bank",
          ]),

          const SizedBox(height: 30),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _openCreditCardPayment(invoiceUrl),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0047FF),
              ),
              child: const Text(
                "Bayar dengan Kartu Kredit",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 16),

          OutlinedButton(
            onPressed: () => _simulatePaymentSuccess(),
            child: const Text("Simulasi Bayar"),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard(List<String> instructions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0047FF).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0047FF).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Cara Pembayaran:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0047FF),
            ),
          ),
          const SizedBox(height: 12),
          ...instructions.map((instruction) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              instruction,
              style: const TextStyle(height: 1.5),
            ),
          )).toList(),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Berhasil disalin ke clipboard"),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _checkPaymentStatus() {
    // In real app, check actual payment status
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Mengecek status pembayaran..."),
        backgroundColor: Color(0xFF0047FF),
      ),
    );
  }

  void _simulatePaymentSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const BookingSuccessPage(),
      ),
    );
  }

  void _openCreditCardPayment(String url) {
    // In real app, open WebView or external browser
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Membuka halaman pembayaran kartu kredit..."),
        backgroundColor: Color(0xFF0047FF),
      ),
    );
  }

  int _calculateCreditCardFee() {
    double percentageFee = widget.price.toDouble() * (2.9 / 100);
    return widget.price + (percentageFee + 2000).round();
  }
}