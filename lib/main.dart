import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'View/Routes/app_routes.dart';
import 'View/Themes/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'amini',
      //themeMode: ThemeMode.system,
      //theme: appTheme,
      //runApp(const MaterialApp(home: VehicleOnboardingScreen()));
      //darkTheme: appDarkTheme,
      routerConfig: router,
    );
  }
}
