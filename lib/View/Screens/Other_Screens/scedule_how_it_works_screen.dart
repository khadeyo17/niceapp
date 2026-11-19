import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  static const Color primaryBlue = Color(0xFF015ACE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        centerTitle: true,
        title:  Text(
          "How It Works",
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20,
            24,
            20,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================================
              // HEADER
              // =====================================================

              Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: primaryBlue,
                    size: 42,
                  ),
                ),
              ),

              const SizedBox(height: 20),

               Center(
                child: Text(
                  "Schedule your ride with AMINI",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              const Center(
                child: Text(
                  "Plan ahead and have your ride ready when "
                  "you need it.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black54,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // =====================================================
              // STEP 1
              // =====================================================

              _buildStep(
                number: "1",
                icon: Icons.location_on_rounded,
                title: "Choose your destination",
                description:
                    "Enter where you want to go and select "
                    "your pickup location.",
              ),

              _buildConnector(),

              // =====================================================
              // STEP 2
              // =====================================================

              _buildStep(
                number: "2",
                icon: Icons.calendar_month_rounded,
                title: "Choose a date and time",
                description:
                    "Select the date and time you would like "
                    "your ride to pick you up.",
              ),

              _buildConnector(),

              // =====================================================
              // STEP 3
              // =====================================================

              _buildStep(
                number: "3",
                icon: Icons.directions_car_rounded,
                title: "Select your ride",
                description:
                    "Choose the vehicle category that best "
                    "suits your trip.",
              ),

              _buildConnector(),

              // =====================================================
              // STEP 4
              // =====================================================

              _buildStep(
                number: "4",
                icon: Icons.check_circle_outline_rounded,
                title: "Confirm your booking",
                description:
                    "Review your trip details and confirm "
                    "your scheduled ride.",
              ),

              _buildConnector(),

              // =====================================================
              // STEP 5
              // =====================================================

              _buildStep(
                number: "5",
                icon: Icons.notifications_active_outlined,
                title: "We'll remind you",
                description:
                    "Your scheduled trip will appear under "
                    "Upcoming Trips so you can easily keep "
                    "track of it.",
              ),

              const SizedBox(height: 32),

              // =====================================================
              // TIP
              // =====================================================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryBlue.withOpacity(0.10),
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: primaryBlue,
                      size: 22,
                    ),

                    const SizedBox(width: 12),

                     Expanded(
                      child:  Text(
                        "Tip: Schedule your ride in advance "
                        "when you know your travel plans. "
                        "This helps you plan your journey "
                        "without having to request a ride "
                        "at the last minute.",
                        style: GoogleFonts.nunitoSans(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // =====================================================
              // BUTTON
              // =====================================================

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "Got it",
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===============================================================
  // STEP WIDGET
  // ===============================================================

  Widget _buildStep({
  required String number,
  required IconData icon,
  required String title,
  required String description,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Number + Icon
      Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: primaryBlue,
              size: 28,
            ),
          ),

          Positioned(
            top: -6,
            right: -6,
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Text(
                number,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),

      const SizedBox(width: 16),

      // Details
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              description,
              style: GoogleFonts.nunitoSans(
                fontSize: 13,
                height: 1.5,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
  // ===============================================================
  // CONNECTOR
  // ===============================================================

  Widget _buildConnector() {
    return Container(
      margin: const EdgeInsets.only(
        left: 28,
        top: 8,
        bottom: 8,
      ),
      width: 2,
      height: 24,
      color: primaryBlue.withOpacity(0.12),
    );
  }
}