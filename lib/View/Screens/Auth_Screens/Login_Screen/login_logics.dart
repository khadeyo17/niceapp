import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:niceapp/Container/Repositories/auth_repo.dart';
import 'package:niceapp/Container/utils/error_notification.dart';
import 'package:niceapp/View/Screens/Auth_Screens/Login_Screen/login_providers.dart';
import 'package:go_router/go_router.dart';

class LoginLogics {
  //   void loginUser(
  //     BuildContext context,
  //     WidgetRef ref,
  //     TextEditingController emailController,
  //     TextEditingController passwordController,
  //   ) async {
  //     try {
  //       if (emailController.text.isEmpty || passwordController.text.isEmpty) {
  //         ErrorNotification().showError(
  //           context,
  //           "Please Enter Email and Password",
  //         );

  //         return;
  //       }
  //       ref.watch(loginIsLoadingProvider.notifier).update((state) => true);
  //       ref
  //           .watch(globalAuthRepoProvider)
  //           .loginUser(
  //             emailController.text.trim(),
  //             passwordController.text.trim(),
  //             context,
  //           );

  //       ref.watch(loginIsLoadingProvider.notifier).update((state) => false);
  //     } catch (e) {
  //       ref.watch(loginIsLoadingProvider.notifier).update((state) => false);
  //       ErrorNotification().showError(context, "An Error Occurred $e");
  //     }
  //   }
  // }

  // void loginUser(
  //   BuildContext context,
  //   WidgetRef ref,
  //   TextEditingController emailController,
  //   TextEditingController passwordController,
  // ) async {
  //   try {
  //     ref.watch(loginIsLoadingProvider.notifier).update((state) => true);

  //     // Check if credentials are empty (optional)
  //     if (emailController.text.isEmpty || passwordController.text.isEmpty) {
  //       ErrorNotification().showError(
  //         context,
  //         "Please Enter Email and Password",
  //       );
  //       return;
  //     }

  //     // Hardcoded credentials for testing
  //     String testEmail = "omaribrahim17@gmail.com";
  //     String testPassword = "test123";

  //     if (emailController.text.trim() == testEmail &&
  //         passwordController.text.trim() == testPassword) {
  //       // Navigate to the home screen
  //       Navigator.pushReplacementNamed(context, '/home');
  //     } else {
  //       // If wrong credentials, still allow login (test mode)
  //       Navigator.pushReplacementNamed(context, '/home'); // Bypass login check
  //     }

  //     ref.watch(loginIsLoadingProvider.notifier).update((state) => false);
  //   } catch (e) {
  //     ref.watch(loginIsLoadingProvider.notifier).update((state) => false);
  //     ErrorNotification().showError(context, "An Error Occurred $e");
  //   }
  // }

  void loginUser(
    BuildContext context,
    WidgetRef ref,
    TextEditingController emailController,
    TextEditingController passwordController,
  ) async {
    try {
      // Bypass login verification
      ref.watch(loginIsLoadingProvider.notifier).update((state) => true);
      context.go('/home');
      // Directly navigate to the home screen (or any destination)
      // GoRouter.of(context).go('/home');
      // Navigator.pushReplacementNamed(
      //  context,
      // '/home',
      //); // Adjust route as needed

      ref.watch(loginIsLoadingProvider.notifier).update((state) => false);
    } catch (e) {
      ref.watch(loginIsLoadingProvider.notifier).update((state) => false);
      ErrorNotification().showError(context, "An Error Occurred $e");
    }
  }
}
