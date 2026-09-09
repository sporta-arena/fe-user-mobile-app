import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'package:flutter/services.dart';
import 'my_booking_page.dart';
import 'home_page.dart';

class BookingSuccessPage extends StatelessWidget {
  const BookingSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: gayaOverlay(context),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Animation/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: context.c.ok.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 80,
                    color: context.c.ok,
                  ),
                ),

                const SizedBox(height: 30),

                // Success Title
                Text(
                  "Pembayaran Berhasil!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.c.ink,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                // Success Message
                Text(
                  "Booking lapangan Anda telah dikonfirmasi.\nDetail booking telah dikirim ke email Anda.",
                  style: TextStyle(
                    fontSize: 16,
                    color: context.c.inkSoft,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Booking Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.c.raised,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.c.line),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.confirmation_number,
                            color: context.c.accent,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Booking ID:",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: context.c.inkSoft,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "SPT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.c.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            color: context.c.accent,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Status:",
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: context.c.inkSoft,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.c.ok,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "CONFIRMED",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // Action Buttons
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyBookingPage(showBackButton: true),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.c.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Lihat My Booking",
                          style: TextStyle(
                            color: context.c.onAccent,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomePage(),
                            ),
                            (route) => false,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.c.line),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          "Kembali ke Home",
                          style: TextStyle(
                            color: context.c.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
