
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/vehicle_category.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';

class PlanAheadScreen extends StatelessWidget {
  const PlanAheadScreen({super.key});

  static const Color primaryBlue = Color(0xFF015ACE);
  static const Color secondaryBlue = Color(0xFF2685DD);
  static const Color yellow = Color(0xFFE9D906);

  static const List<Map<String, String>> transportServices = [
    {
      'name': 'Taxi',
      'image': 'assets/imgs/taxi.png',
      'route': '/services/transport/ride-booking',
    },
    {
      'name': 'Machinery',
      'image': 'assets/imgs/machineryx.png',
      'route': '/services/transport/machinery',
    },
    {
      'name': 'Clean Water',
      'image': 'assets/imgs/cleanwater.png',
      'route': '/services/transport/water-bower',
    },
    {
      'name': 'Exhauster',
      'image': 'assets/imgs/exhausterx.png',
      'route': '/services/transport/honey-sucker',
    },
  ];

  // =========================================================
  // NAVIGATE TO SELECTED SERVICE
  // =========================================================

void _navigateToService(
  BuildContext context,
  Map<String, String> service,
) {
  final route = service['route'];

  if (route == null) return;

  context.push(
    route,
    extra: {
      'IsScheduled': true,
    },
  );
}

  // =========================================================
  // SERVICE CARD
  // =========================================================

  Widget _buildServiceCard(
    BuildContext context,
    Map<String, String> service,
  ) {
    return GestureDetector(
      onTap: () => _navigateToService(context, service),
      child: SizedBox(
        width: 156,
        height: 124,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: 156,
              height: 82,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: yellow,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.035),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                service['image']!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_not_supported_outlined,
                    color: primaryBlue,
                    size: 35,
                  );
                },
              ),
            ),

            // SERVICE NAME
            Positioned(
              top: 70,
              child: Container(
                height: 26,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: yellow,
                    width: 2,
                  ),
                ),
                child: Text(
                  service['name']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUILD SCREEN
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Plan Ahead',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Text(
                'Schedule your next trip',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Choose a service and schedule it for a date and time that works for you.',
                style: GoogleFonts.nunitoSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF777777),
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // SECTION TITLE
              Text(
                'SELECT A SERVICE',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: const Color(0xFF777777),
                ),
              ),

              const SizedBox(height: 18),

              // SERVICES GRID
              SizedBox(
                width: double.infinity,
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transportServices.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 18,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 124,
                  ),
                  itemBuilder: (context, index) {
                    final service = transportServices[index];

                    return _buildServiceCard(
                      context,
                      service,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
