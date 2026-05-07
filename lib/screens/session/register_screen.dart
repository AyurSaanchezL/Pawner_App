import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/screens/session/log_in_screen.dart';
import 'package:pawner_app/services/auth_service.dart';
import 'package:pawner_app/services/crash_manager.dart';
import 'package:pawner_app/services/firestore_service.dart';
import 'package:pawner_app/screens/familia/elegir_familia.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String username = "";
  TextEditingController controllerUsername = TextEditingController();
  TextEditingController controllerCorreo = TextEditingController();
  TextEditingController controllerPassword = TextEditingController();

  Future<void> _registrarse() async {
    // 1. Validación básica antes de llamar a Firebase
    if (controllerUsername.text.isEmpty ||
        controllerCorreo.text.isEmpty ||
        controllerPassword.text.isEmpty) {
      _mostrarSnackBar("Por favor, completa todos los campos");
      return;
    }

    try {
      // 2. Creación de cuenta
      UserCredential credential = await authService.value.createAccount(
        email: controllerCorreo.text.trim(),
        password: controllerPassword.text.trim(),
      );

      // 3. Verificación de nulidad segura
      final user = credential.user;
      if (user != null) {
        String realUID = user.uid;

        // 4. Guardar en Firestore
        await FirestoreService().addUsuario(
          Usuario(
            "",
            controllerUsername.text,
            controllerCorreo.text,
            'zorro',
            null,
            null,
          ),
          realUID,
        );

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const ElegirFamiliaLayout(),
            ),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String mensajeError = _mapearErrorFirebase(e.code);
      _mostrarSnackBar(mensajeError);
      log("Error de Firebase: ${e.code} - ${e.message}");
      await firebaseController.reportCrash(e, e.stackTrace);
    } catch (e, stack) {
      // Aquí capturamos el famoso "Null check operator" o errores de Firestore
      log("Error genérico capturado: $e");
      log("Stacktrace: $stack");
      _mostrarSnackBar("Error inesperado: $e");
    }
  }

  // Función auxiliar para no repetir código del SnackBar
  void _mostrarSnackBar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, textAlign: TextAlign.center),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _mapearErrorFirebase(String code) {
    switch (code) {
      case 'invalid-email':
        return "El formato del correo no es válido.";
      case 'email-already-in-use':
        return "El correo ya está en uso.";
      case 'weak-password':
        return "La contraseña es muy débil (min. 6 caracteres).";
      case 'network-request-failed':
        return "Error de conexión a internet.";
      default:
        return "Error en el registro. Inténtalo de nuevo.";
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

                    SizedBox(height: 100),
                    SizedBox(height: 25),
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
