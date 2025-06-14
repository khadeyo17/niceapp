import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:niceapp/View/Components/all_components.dart';
import 'package:niceapp/View/Routes/routes.dart';
import 'package:niceapp/View/Screens/Auth_Screens/Login_Screen/login_logics.dart';
import 'package:niceapp/View/Screens/Auth_Screens/Login_Screen/login_providers.dart';
//import '../../../Routes/_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: SafeArea(
        child: InkWell(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              children: [
                Opacity(
                  opacity: 0.2,
                  child: Container(
                    width: size.width,
                    height: size.height,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: AssetImage("assets/imgs/main.jpg"),
                      ),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        "Login",
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontFamily: "bold",
                          fontSize: 20,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 20.0,
                          left: 20,
                          right: 20,
                        ),
                        child: Form(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Components().returnTextField(
                                emailController,
                                context,
                                false,
                                "Enter Email",
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Components().returnTextField(
                                  passwordController,
                                  context,
                                  true,
                                  "Enter Password",
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    return InkWell(
                                      onTap:
                                          ref.watch(loginIsLoadingProvider)
                                              ? null
                                              : () => LoginLogics().loginUser(
                                                context,
                                                ref,
                                                emailController,
                                                passwordController,
                                              ),
                                      child: Components().mainButton(
                                        size,
                                        ref.watch(loginIsLoadingProvider)
                                            ? "Loading ..."
                                            : "Login",
                                        context,
                                        ref.watch(loginIsLoadingProvider)
                                            ? Colors.grey
                                            : Colors.blue,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.goNamed(Routes().register);
                                },
                                child: Text(
                                  "Don't have an account? Sign Up.",
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall!.copyWith(
                                    fontFamily: "bold",
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
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
