import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        title: Text(
          "Help",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "How can we help?",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Find answers to common questions about using AMINI.",
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 25),

          _helpItem(
            "How do I book a ride?",
            "Choose your pickup and destination, select your ride option and confirm your booking.",
          ),

          _helpItem(
            "How do I schedule a ride?",
            "Select Schedule Ride, choose your pickup and destination, then select the date and time.",
          ),

          _helpItem(
            "How do I pay for a ride?",
            "You can use the available payment options configured in your AMINI wallet.",
          ),

          _helpItem(
            "How do I cancel a ride?",
            "Open your active trip and select the cancellation option.",
          ),
        ],
      ),
    );
  }

  Widget _helpItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F4),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16,
        ),
        children: [
          Text(
            description,
            style: GoogleFonts.nunitoSans(
              fontSize: 14,
              height: 1.5,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}