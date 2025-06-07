import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:niceapp/Container/Repositories/auth_repo.dart';
import 'package:niceapp/Container/utils/error_notification.dart';
import 'package:niceapp/View/Screens/Auth_Screens/Register_Screen/register_providers.dart';

class RegisterLogics {
  Future<void> registerUser(
    BuildContext context,
    WidgetRef ref,
    TextEditingController nameController,
    TextEditingController emailController,
    TextEditingController passwordController,
    String phoneNumber,
    //bool isPhone, // future-proof flag for phone-based registration
  ) async {
    if (nameController.text.isEmpty ||
        phoneNumber.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ErrorNotification().showError(
        context,
        "Please enter Name, Email,Phone, and Password",
      );
      return;
    }

    ref.read(registerIsLoadingProvider.notifier).state = true;

    try {
      {
        // Register with email, phone, and password
        // await ref
        //     .read(globalAuthRepoProvider)
        //     //.registerWithEmailPhonePassword(
        //       fullName: nameController.text.trim(),
        //       email: emailController.text.trim(),
        //       phone: phoneNumber.trim(),
        //       password: passwordController.text.trim(),
        //       context: context,
        //     );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        ErrorNotification().showError(
          context,
          "An account already exists for that email.",
        );
      } else {
        ErrorNotification().showError(
          context,
          e.message ?? "An error occurred",
        );
      }
    } catch (e) {
      ErrorNotification().showError(
        context,
        "An unexpected error occurred: $e",
      );
    } finally {
      ref.read(registerIsLoadingProvider.notifier).state = false;
    }
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:niceapp/Container/Repositories/auth_repo.dart';
// import 'package:niceapp/Container/utils/error_notification.dart';
// import 'package:niceapp/View/Screens/Auth_Screens/Register_Screen/register_providers.dart';

// class RegisterLogics {
//   void registerUser(
//     BuildContext context,
//     WidgetRef ref,
//     TextEditingController nameController,
//     TextEditingController emailController,
//     TextEditingController passwordController,
//   ) async {
//     try {
//       if (nameController.text.isEmpty ||
//           emailController.text.isEmpty ||
//           passwordController.text.isEmpty) {
//         ErrorNotification().showError(
//           context,
//           "Please Enter Email and Password",
//         );

//         return;
//       }

//       ref.watch(registerIsLoadingProvider.notifier).update((state) => true);
//       ref
//           .watch(globalAuthRepoProvider)
//           .registerUser(
//             emailController.text.trim(),
//             passwordController.text.trim(),
//             context,
//           );

//       ref.watch(registerIsLoadingProvider.notifier).update((state) => false);
//     } catch (e) {
//       ref.watch(registerIsLoadingProvider.notifier).update((state) => false);
//       ErrorNotification().showError(context, "An Error Occurred $e");
//     }
//   }
// }
