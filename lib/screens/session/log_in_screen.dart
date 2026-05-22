import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/screens/session/register_screen.dart';
import 'package:pawner_app/screens/usuario/dashboard_screen.dart';
import 'package:pawner_app/services/auth_service.dart';
import 'package:pawner_app/services/crash_manager.dart';
import 'package:pawner_app/screens/familia/elegir_familia.dart';
import 'package:pawner_app/services/firestore_service.dart';

class LogInScreen extends StatefulWidget {
  const LogInScreen({super.key});

  @override
  State<LogInScreen> createState() => _LogInScreenState();
}

TextEditingController controllerEmail = TextEditingController();
TextEditingController controllerPassword = TextEditingController();

class _LogInScreenState extends State<LogInScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.secondary,
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
      backgroundColor: AppColors.lightSecondary,
      body: ListView(
        children: [
          SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 40),
                // =============== LOGO ==============
                Image.asset("assets/images/logo-azul-tick.png", width: 180),
                SizedBox(height: 50),
                Column(
                  children: [
                    // =============== EMAIL ==============
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 20,
                        left: 40,
                        right: 40,
                      ),
                      child: TextField(
                        maxLines: 1,
                        keyboardType: .emailAddress,
                        controller: controllerEmail,
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
                        _iniciarSesion(context);
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
                        "Iniciar Sesión",
                        style: TextStyle(fontWeight: .w600, fontSize: 18),
                      ),
                    ),

                    SizedBox(height: 5),
                    // =============== REGISTRARSE ==============
                    RichText(
                      text: TextSpan(
                        style: TextStyle(color: AppColors.dark, fontSize: 15),
                        children: <TextSpan>[
                          TextSpan(text: "¿No tienes cuenta? "),
                          TextSpan(
                            text: "Regístrate",
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: .w700,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RegisterScreen(),
                                  ),
                                );
                              },
                          ),
                        ],
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

  Future<void> _iniciarSesion(BuildContext inContext) async {
    try {
      UserCredential credential = await AuthService().signIn(
        email: controllerEmail.text,
        password: controllerPassword.text,
      );

      // Obtener datos del usuario desde Firestore
      final usuario = await FirestoreService().getCurrentUser(credential.user!);

      if (context.mounted) {
        if (usuario.familiaID == null || usuario.familiaID!.isEmpty) {
          // Redirigir a elegir familia si no tiene una
          Navigator.pushReplacement(
            inContext,
            MaterialPageRoute(
              builder: (context) => const ElegirFamiliaLayout(),
            ),
          );
        } else {
          // Redirigir al dashboard si ya tiene familia
          Navigator.pushReplacement(
            inContext,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensajeError = "Error al iniciar sesión";

      switch (e.code) {
        case 'user-not-found':
          mensajeError = "No existe ninguna cuenta con este correo.";
          break;
        case 'wrong-password':
          mensajeError = "La contraseña es incorrecta.";
          break;
        case 'invalid-credential':
          // Firebase ahora suele devolver este para ambos casos por seguridad
          mensajeError = "Email o contraseña incorrectos.";
          break;
        case 'user-disabled':
          mensajeError = "Esta cuenta ha sido deshabilitada.";
          break;
        case 'invalid-email':
          mensajeError = "El formato del correo no es válido.";
          break;
        case 'too-many-requests':
          mensajeError = "Demasiados intentos. Inténtalo más tarde.";
          break;
        case 'channel-error':
          mensajeError = "Por favor, rellena todos los campos.";
          break;
        default:
          mensajeError = "Error: ${e.message}";
      }

      if (context.mounted) {
        ScaffoldMessenger.of(inContext).showSnackBar(
          SnackBar(
            content: Text(mensajeError, textAlign: TextAlign.center),
            backgroundColor: Colors.red,
          ),
        );
      }

      log("Error de Login: ${e.code}");
      await firebaseController.reportCrash(e, e.stackTrace);
    } catch (e) {
      log("Error inesperado: $e");
    }
  }
}
