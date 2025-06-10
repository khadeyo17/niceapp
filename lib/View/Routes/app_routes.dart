//import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:niceapp/View/Screens/Auth_Screens/Register_Screen/lets_get_started_screen.dart';
import 'package:niceapp/View/Screens/Auth_Screens/Register_Screen/mobile_entry_screen.dart';
import 'package:niceapp/View/Screens/Auth_Screens/Register_Screen/mobile_otp_verification_screen.dart';
import 'package:niceapp/View/Screens/Auth_Screens/Register_Screen/profile_setup_screen.dart';
import 'package:niceapp/View/Screens/Auth_Screens/Register_Screen/register_screen.dart';
//import 'package:google_maps_flutter/google_maps_flutter.dart';
//import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/dashboard_screen';
//import 'package:niceapp/View/Routes/routes.dart';
import 'package:niceapp/View/Screens/Main_Screens/Home_Screen/main_layout.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_confirmation_screen.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/driver_provider.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/where_to_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/Splash_Screen/splash_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/break_down.dart';
import 'package:niceapp/View/Screens/Other_Screens/bus_booking_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/cargo_transport.dart';
import 'package:niceapp/View/Screens/Other_Screens/carhire_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/financial_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/honey_sucker_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/mechanical_screen.dart';
//import 'package:niceapp/View/Screens/Other_Screens/map_screen';
import 'package:niceapp/View/Screens/Other_Screens/movers_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/passenger_ride_booking_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/payments_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/profile_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/ride_history_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/school_transport_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/services_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/transport_screen.dart'
    show TransportServicesScreen;
import 'package:niceapp/View/Screens/Other_Screens/wallet_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/water_bower_screen.dart';
import 'package:niceapp/View/Screens/Other_Screens/ambulance_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => SplashScreen()),
    //Authentication Routes
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (BuildContext context, GoRouterState state) {
        return const RegisterScreen();
      },
      //       return const LoginScreen();
      //     },
      //builder: (context, state) => LoginScreen(),
    ),

    // GoRoute(
    //   name: 'whereTo',
    //   path: '/whereTo',
    //   builder: (BuildContext context, GoRouterState state) {
    //     final GoogleMapController? controller =
    //         state.extra as GoogleMapController?;
    //     return WhereToScreen(controller: controller);
    //   },
    // ),
    GoRoute(
      name: 'whereTo',
      path: '/whereTo',
      builder: (context, state) => const WhereToScreen(),
    ),
    // GoRoute(
    //   path: '/otp',
    //   name: 'otp',
    //   builder: (context, state) {
    //     final extra = state.extra as Map<String, dynamic>?;
    //     print("Navigated to OTP with extra: $extra");

    //     final verificationId = extra?['verificationId'] ?? '';
    //     final phoneNumber = extra?['phoneNumber'] ?? '';

    //     return OTPVerificationScreen(
    //       verificationId: verificationId,
    //       phoneNumber: phoneNumber,
    //     );
    //   },
    // ),
    GoRoute(
      name: 'otp',
      path: '/otp',
      pageBuilder: (context, state) {
        final extras = state.extra as Map<String, dynamic>?;

        if (extras == null ||
            extras['verificationId'] == null ||
            extras['phoneNumber'] == null) {
          return MaterialPage(
            child: Scaffold(
              body: Center(
                child: Text('Verification ID is missing. Please retry.'),
              ),
            ),
          );
        }

        return MaterialPage(
          child: OTPVerificationScreen(
            verificationId: extras['verificationId'],
            phoneNumber: extras['phoneNumber'],
          ),
        );
      },
    ),

    GoRoute(
      path: '/register',
      name: 'register',
      builder: (BuildContext context, GoRouterState state) {
        return const RegisterScreen();
      },
      //builder: (context, state) => RegisterScreen(),
    ),
    GoRoute(
      path: '/profilesetupscreen',
      name: 'profilesetupscreen',
      builder: (BuildContext context, GoRouterState state) {
        return const ProfileSetupScreen();
      },
      //builder: (context, state) => RegisterScreen(),
    ),
    // GoRoute(
    //   path: '/driverConfirmation',
    //   name: 'driverConfirmation',
    //   builder: (BuildContext context, GoRouterState state) {
    //     final driver = state.extra as Driver;
    //     return DriverConfirmationScreen(
    //       driver: driver,
    //       onConfirm: () {
    //         // TODO: Define what should happen on confirm
    //         print("Ride confirmed");
    //       },
    //     );
    //   },
    // ),

    ///driverConfirmation

    // // Auth Routes
    //   GoRoute(
    //     name: Routes().login,
    //     path: '/${Routes().login}',
    //     builder: (BuildContext context, GoRouterState state) {
    //       return const LoginScreen();
    //     },
    //   ),
    //   GoRoute(
    //     name: Routes().register,
    //     path: '/${Routes().register}',
    //     builder: (BuildContext context, GoRouterState state) {
    //       return const RegisterScreen();
    //     },
    //   ),
    //   GoRoute(
    //     name: Routes().home,
    //     path: '/${Routes().home}',
    //     builder: (BuildContext context, GoRouterState state) {
    //       return const HomeScreen();
    //     },
    //   ),

    // Main App Routes (With Bottom Navigation)
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          builder:
              (context, state) =>
                  const TransportServicesScreen(), //const HomeScreen(),
          routes: [
            // GoRoute(
            //   path: 'ride',
            //   name: 'ride',
            //   builder: (context, state) => const HomeScreen(),
            // ),
            // GoRoute(
            //   path: 'ride-history',
            //   name: 'rideHistory',
            //   builder: (context, state) => const RideHistoryScreen(),
            // ),
          ],
        ),
        GoRoute(
          path: '/services',
          name: 'services',
          builder: (context, state) => const ServicesScreen(),
          routes: [
            GoRoute(
              path: 'financial',
              name: 'financialServices',
              builder: (context, state) => const FinancialServicesScreen(),
              routes: [
                GoRoute(
                  path: 'payments',
                  name: 'payments',
                  builder: (context, state) => PaymentScreen(),
                ),
                GoRoute(
                  path: 'wallet',
                  name: 'wallet',
                  builder: (context, state) => WalletScreen(),
                ),
              ],
            ),
            GoRoute(
              path: 'transport',
              name: 'transportServices',
              builder: (context, state) => const TransportServicesScreen(),
              routes: [
                GoRoute(
                  path: 'ride-booking',
                  name: 'rideBooking',
                  builder: (context, state) => HomeScreen(),
                ),
                GoRoute(
                  path: 'bus-booking',
                  name: 'busBooking',
                  builder: (context, state) => BusBookingScreen(),
                ),
                GoRoute(
                  path: 'honey-sucker',
                  name: 'honeySucker',
                  builder: (context, state) => HoneySuckerScreen(),
                ),
                GoRoute(
                  path: 'movers',
                  name: 'movers',
                  builder: (context, state) => MoversScreen(),
                ),
                GoRoute(
                  path: 'cargo',
                  name: 'cargoTransport',
                  builder: (context, state) => const CargoTransportScreen(),
                ),
                GoRoute(
                  path: 'car-hire',
                  name: 'carHire',
                  builder: (context, state) => const CarHireScreen(),
                ),
                GoRoute(
                  path: 'ambulance',
                  name: 'ambulance',
                  builder: (context, state) => const AmbulanceScreen(),
                ),
                GoRoute(
                  path: 'water-bower',
                  name: 'waterBower',
                  builder: (context, state) => const WaterBowerScreen(),
                ),
                GoRoute(
                  path: 'breakdown',
                  name: 'breakdown',
                  builder: (context, state) => const BreakdownScreen(),
                ),
                GoRoute(
                  path: 'mechanical',
                  builder: (context, state) => const MechanicalScreen(),
                ),
                GoRoute(
                  path: 'school-transport',
                  builder: (context, state) => const SchoolTransportScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/events',
          name: 'events',
          builder: (context, state) => const RideHistoryScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
//   initialLocation: '/login', // Start with the login screen
//   routes: [
//     /// Authentication Routes (No Bottom Navigation)
//     GoRoute(
//       path: '/login',
//       name: 'login',
//       builder: (context, state) => const LoginScreen(),
//     ),
//     GoRoute(
//       path: '/register',
//       name: 'register',
//       builder: (context, state) => const RegisterScreen(),
//     ),

//     /// Main App Routes (With Bottom Navigation)
//     ShellRoute(
//       builder: (context, state, child) => MainLayout(child: child),
//       routes: [
//         GoRoute(
//           path: '/',
//           name: 'home',
//           builder: (context, state) => const HomeScreen(),
//         ),
//         GoRoute(
//           path: '/ride-history',
//           name: 'rideHistory',
//           builder: (context, state) => const RideHistoryScreen(),
//         ),
//         GoRoute(
//           path: '/services',
//           name: 'services',
//           builder: (context, state) => const ServicesScreen(),
//           routes: [
//             GoRoute(
//               path: 'financial',
//               name: 'financialServices',
//               builder: (context, state) => const FinancialServicesScreen(),
//               routes: [
//                 GoRoute(
//                   path: 'payments',
//                   name: 'payments',
//                   builder: (context, state) => const PaymentsScreen(),
//                 ),
//                 GoRoute(
//                   path: 'wallet',
//                   name: 'wallet',
//                   builder: (context, state) => const WalletScreen(),
//                 ),
//               ],
//             ),
//             GoRoute(
//               path: 'transport',
//               name: 'transportServices',
//               builder: (context, state) => const TransportServicesScreen(),
//               routes: [
//                 GoRoute(
//                   path: 'bus-booking',
//                   name: 'busBooking',
//                   builder: (context, state) => const BusBookingScreen(),
//                 ),
//                 GoRoute(
//                   path: 'honey-sucker',
//                   name: 'honeySucker',
//                   builder: (context, state) => const HoneySuckerScreen(),
//                 ),
//                 GoRoute(
//                   path: 'movers',
//                   name: 'movers',
//                   builder: (context, state) => const MoversScreen(),
//                 ),
//                 GoRoute(
//                   path: 'cargo',
//                   name: 'cargoTransport',
//                   builder: (context, state) => const CargoTransportScreen(),
//                 ),
//                 GoRoute(
//                   path: 'car-hire',
//                   name: 'carHire',
//                   builder: (context, state) => const CarHireScreen(),
//                 ),
//                 GoRoute(
//                   path: 'ambulance',
//                   name: 'ambulance',
//                   builder: (context, state) => const AmbulanceScreen(),
//                 ),
//                 GoRoute(
//                   path: 'water-bower',
//                   name: 'waterBower',
//                   builder: (context, state) => const WaterBowerScreen(),
//                 ),
//                 GoRoute(
//                   path: 'breakdown',
//                   name: 'breakdown',
//                   builder: (context, state) => const BreakdownScreen(),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         GoRoute(
//           path: '/profile',
//           name: 'profile',
//           builder: (context, state) => const ProfileScreen(),
//         ),
//       ],
//     ),
//   ],
// );
