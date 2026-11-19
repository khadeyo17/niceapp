// import 'package:flutter/material.dart';

// ThemeData appTheme = ThemeData(
//   useMaterial3: true,
//   scaffoldBackgroundColor: Colors.black,
//   textTheme:
//       const TextTheme(
//         bodySmall: TextStyle(
//           color: Colors.white,
//           fontFamily: "regular",
//           fontSize: 16,
//         ),
//         bodyMedium: TextStyle(
//           color: Colors.white,
//           fontFamily: "medium",
//           fontSize: 20,
//         ),
//         bodyLarge: TextStyle(
//           color: Colors.white,
//           fontFamily: "bold",
//           fontSize: 22,
//         ),
//       ).apply(),
// );
import 'package:flutter/material.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.white,
  textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.black)),
  iconTheme: const IconThemeData(color: Colors.yellow),
);

final ThemeData appDarkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.black,
  textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
  iconTheme: const IconThemeData(color: Colors.yellow),
);
