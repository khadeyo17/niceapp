import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:niceapp/View/Screens/Main_Screens/Sub_Screens/Where_To_Screen/ride_status_burner.dart';
import 'View/Routes/app_routes.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

// TOP-LEVEL background handler (required by Firebase Messaging)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

// Local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInit,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

void showNotification(RemoteMessage message) {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'vicsacs_channel', // channel id
    'Vicsacs Notifications', // channel name
    channelDescription: 'Channel for ride notifications',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  const NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? message.data['title'] ?? 'No title',
    message.notification?.body ?? message.data['body'] ?? 'No body',
    notificationDetails,
  );
}

Future<void> setupPushNotifications() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission (iOS + Android 13+)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print('User granted permission: ${settings.authorizationStatus}');

  // Get token for testing (print it)
  String? token = await messaging.getToken();
  print("🔥 FCM Token: $token");

  // Foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Foreground message: ${message.messageId}");
    showNotification(message);
  });

  // Tapped notifications (background → foreground)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("🔔 Notification tapped: ${message.messageId}");
  });
}

// Future<void> setupAppCheck() async {
//   await FirebaseAppCheck.instance.activate(
//     androidProvider:
//         kDebugMode
//             ? AndroidProvider
//                 .debug // for local / manual testing
//             : AndroidProvider
//                 .playIntegrity, // for internal or production builds
//   );
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('cacheBox');
  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Setup background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Init local notifications
  await initLocalNotifications();

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
  );

  // ✅ Only use ProviderScope (Riverpod)
  runApp(const ProviderScope(child: MyApp()));

  // Run push setup in the background
  setupPushNotifications();
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // return StreamBuilder<User?>(
    //   stream: FirebaseAuth.instance.authStateChanges(),
    //   builder: (context, snapshot) {
    //     final userId = snapshot.data?.uid;

    //     return MaterialApp.router(
    //       debugShowCheckedModeBanner: false,
    //       routerConfig: router,
    //       builder: (context, child) {
    //         // This context is under GoRouter
    //         return Stack(
    //           children: [
    //             child!,
    //             if (userId != null)
    //               Builder(
    //                 builder: (context) {
    //                   // Now this context is definitely under GoRouter
    //                   return RideStatusBanner(userId: userId);
    //                 },
    //               ),
    //           ],
    //         );
    //       },
    //     );
    //   },
    // );
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      //navigatorKey: navigatorKey,
      builder: (context, child) {
        // This context is under GoRouter
        return AuthAndBannerWrapper(child: child!);
      },
    );
  }
}

class AuthAndBannerWrapper extends ConsumerWidget {
  final Widget child;
  const AuthAndBannerWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final userId = snapshot.data?.uid;

        return Stack(
          children: [
            child,
            if (userId != null) RideStatusBanner(userId: userId),
          ],
        );
      },
    );
  }
}

// class MyApp extends ConsumerWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Example: Watching ride status for a test user
//     // In real app replace "user123" with logged-in userId
//     // final user = FirebaseAuth.instance.currentUser;

//     // final userId = user?.uid;
//     // //final rideStatusAsync = ref.watch(rideStatusStreamProvider(userId!));

//     // return MaterialApp.router(
//     //   debugShowCheckedModeBanner: false,
//     //   routerConfig: router,

//     //   builder: (context, child) {
//     //     return Stack(
//     //       children: [
//     //         child!,
//     //         if (userId != null)
//     //           RideStatusBanner(userId: userId), // ✅ only when available
//     //       ],
//     //     );
//     //   },
//     // );

//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         final userId = snapshot.data?.uid;

//         // return MaterialApp.router(
//         //   debugShowCheckedModeBanner: false,
//         //   routerConfig: router,
//         //   builder: (context, child) {
//         //     return Builder(
//         //       builder: (context) {
//         //         // This context is now *inside* GoRouter
//         //         return Stack(
//         //           children: [
//         //             child!,
//         //             if (userId != null) RideStatusBanner(userId: userId),
//         //           ],
//         //         );
//         //       },
//         //     );
//         //   },
//         // );
//         return MaterialApp.router(
//           debugShowCheckedModeBanner: false,
//           routerConfig: router,
//           builder: (context, child) {
//             return Stack(
//               children: [
//                 child!, // This is inside GoRouter
//                 if (userId != null)
//                   Builder(
//                     builder: (context) {
//                       // This context is now under GoRouter
//                       return RideStatusBanner(userId: userId);
//                     },
//                   ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'View/Routes/app_routes.dart';

// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// import 'firebase_options.dart';
// import 'ride_status_provider.dart';

// // TOP-LEVEL background handler (required by Firebase Messaging)
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
//   print("Handling a background message: ${message.messageId}");
// }
// final rideStatusProvider =
//     ChangeNotifierProvider<RideStatusNotifier>((ref) => RideStatusNotifier());
// // Local notifications plugin
// final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//     FlutterLocalNotificationsPlugin();

// Future<void> initLocalNotifications() async {
//   const AndroidInitializationSettings androidInit =
//       AndroidInitializationSettings('@mipmap/ic_launcher');

//   const InitializationSettings initSettings = InitializationSettings(
//     android: androidInit,
//   );

//   await flutterLocalNotificationsPlugin.initialize(initSettings);
// }

// void showNotification(RemoteMessage message) {
//   const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//     'vicsacs_channel', // channel id
//     'Vicsacs Notifications', // channel name
//     channelDescription: 'Channel for ride notifications',
//     importance: Importance.max,
//     priority: Priority.high,
//     playSound: true,
//   );

//   const NotificationDetails notificationDetails = NotificationDetails(
//     android: androidDetails,
//   );

//   flutterLocalNotificationsPlugin.show(
//     0,
//     message.notification?.title ?? message.data['title'] ?? 'No title',
//     message.notification?.body ?? message.data['body'] ?? 'No body',
//     notificationDetails,
//   );
// }

// Future<void> setupPushNotifications() async {
//   FirebaseMessaging messaging = FirebaseMessaging.instance;

//   // Request permission (iOS + Android 13+)
//   NotificationSettings settings = await messaging.requestPermission(
//     alert: true,
//     badge: true,
//     sound: true,
//   );

//   print('User granted permission: ${settings.authorizationStatus}');

//   // Get token for testing (print it)
//   String? token = await messaging.getToken();
//   print("🔥 FCM Token: $token");

//   // Foreground messages
//   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//     print("📩 Foreground message: ${message.messageId}");
//     showNotification(message);
//   });

//   // Tapped notifications (background → foreground)
//   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//     print("🔔 Notification tapped: ${message.messageId}");
//   });
// }

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize Firebase
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   // Setup background handler
//   FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//   // Init local notifications (very fast)
//   await initLocalNotifications();

//   // Don’t wait for push setup here — run after UI is up
//   //runApp(const ProviderScope(child: MyApp( )));
//   runApp(
//     ProviderScope(
//       child: ChangeNotifierProvider(
//         create: (_) => RideStatusNotifier(),
//         child: const MyApp(),
//       ),
//     ),
//   );

//   // Run push setup in the background
//   setupPushNotifications();
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final rideStatus = ref.watch(rideStatusProvider).rideStatus;
//     return MaterialApp.router(
//       debugShowCheckedModeBanner: false,
//       routerConfig: router,
//     );
//   }
// }
// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:flutter/material.dart';
// // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // import 'View/Routes/app_routes.dart';
// // import 'package:firebase_core/firebase_core.dart';
// // import 'firebase_options.dart';

// // Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
// //   print("Handling a background message: ${message.messageId}");
// // }

// // void main() async {
// //   // Ensures binding is initialized before any async calls
// //   WidgetsFlutterBinding.ensureInitialized();

// //   // Initialize Firebase asynchronously without blocking UI unnecessarily
// //   // Consider using Flutter's native splash screen to cover the loading delay
// //   Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform).then((
// //     _,
// //   )

// //   {
// //     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

// //     runApp(const ProviderScope(child: MyApp()));
// //   });
// // }

// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});

// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp.router(
// //       debugShowCheckedModeBanner: false,
// //       routerConfig: router,
// //     );
// //   }
// // }

// // // import 'package:flutter/material.dart';
// // // import 'package:flutter_riverpod/flutter_riverpod.dart';
// // // import 'package:niceapp/View/Screens/Other_Screens/passenger_location_live.dart';
// // // import 'View/Routes/app_routes.dart';
// // // import 'package:firebase_core/firebase_core.dart';
// // // import 'firebase_options.dart';

// // // Future<void> main() async {
// // //   WidgetsFlutterBinding.ensureInitialized();
// // //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// // //  // PassengerLocationLive().startSendingLocation();
// // //   runApp(const ProviderScope(child: MyApp()));
// // // }

// // // class MyApp extends StatelessWidget {
// // //   const MyApp({super.key});
// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return MaterialApp.router(
// // //       debugShowCheckedModeBanner: false,
// // //       //title: 'amini',
// // //       //themeMode: ThemeMode.system,
// // //       //theme: appTheme,
// // //       //runApp(const MaterialApp(home: VehicleOnboardingScreen()));
// // //       //darkTheme: appDarkTheme,
// // //       routerConfig: router,
// // //     );
// // //   }
// // // }
