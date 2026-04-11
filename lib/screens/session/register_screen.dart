import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/auth_service.dart';
import 'package:pawner_app/core/firebase_pawner_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? username;
  String? correo;
  String? password;
  TextEditingController controllerUsername = TextEditingController();
  TextEditingController controllerCorreo = TextEditingController();
  TextEditingController controllerPassword = TextEditingController();

  void _registrarse() async {
    try {
      await authService.value.createAccount(
        email: controllerCorreo.text,
        password: controllerPassword.text,
      );
      popPage();
    } on FirebaseAuthException catch (e) {
      log(e.message!);
      await firebaseController.reportCrash(e, e.stackTrace);
    }
  }

  void popPage() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.complementary,
        centerTitle: true,
        toolbarHeight: 40,
        title: Text(
          "PAWNER",
          style: TextStyle(fontSize: 20, fontWeight: .w600),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.arrow_back_ios),
        ),
      ),
      backgroundColor: AppColors.accent,
      body: ListView(
        children: [
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                // =============== LOGO ==============
                Image.asset("assets/images/logo-azul-tick.png", width: 160),
                SizedBox(height: 50),
                Column(
                  children: [
                    // =============== USER ==============
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 20,
                        left: 40,
                        right: 40,
                      ),
                      child: TextField(
                        maxLines: 1,
                        controller: controllerUsername,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 8,
                          ),
                          hint: Text(
                            "Nombre de usuario",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
                              fontSize: 18,
                            ),
                          ),
                          prefixIcon: Icon(Icons.person),
                          fillColor: AppColors.primary,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    // =============== EMAIL ==============
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 20,
                        left: 40,
                        right: 40,
                      ),
                      child: TextField(
                        controller: controllerCorreo,
                        maxLines: 1,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 8,
                          ),
                          hint: Text(
                            "E-Mail",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
                              fontSize: 18,
                            ),
                          ),
                          prefixIcon: Icon(Icons.mail),
                          fillColor: AppColors.primary,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    // =============== PASSWORD ==============
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 20,
                        left: 40,
                        right: 40,
                      ),
                      child: TextField(
                        controller: controllerPassword,
                        maxLines: 1,
                        obscureText: true,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 8,
                          ),
                          hint: Text(
                            "Contraseña",
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.dark,
                              fontSize: 18,
                            ),
                          ),
                          prefixIcon: Icon(Icons.password),
                          fillColor: AppColors.primary,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 125),
                    // =============== BOTÓN ==============
                    ElevatedButton(
                      onPressed: () {
                        _registrarse();
                      },
                      style: ButtonStyle(
                        backgroundColor: .all(AppColors.secondary),
                        foregroundColor: .all(AppColors.primary),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      child: Text(
                        "Registrarse",
                        style: TextStyle(fontWeight: .w600, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
