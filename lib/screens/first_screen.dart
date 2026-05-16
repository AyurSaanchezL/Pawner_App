import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/screens/session/log_in_screen.dart';
import 'package:pawner_app/screens/usuario/dashboard_screen.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  // Con esta función comprobamos que no han pasado más de 30 días desde el último inicio de sesión del usuario.
  // Si ha caducado ese tiempo, vuelve a pedir que inicie sesión para mantener la seguridad de la cuenta
  Future<void> _verifySessionTimeout(User u) async {
    try {
      final idTokenResult = await u.getIdTokenResult();
      final authTime = idTokenResult.authTime;

      if (authTime != null) {
        final ahora = DateTime.now();
        final diferencia = ahora.difference(authTime).inDays;

        log("Auth Time: $authTime y la diferencia: $diferencia");

        if (diferencia >= 30) {
          await FirebaseAuth.instance.signOut();
        }
      }
    } catch (e) {
      // Posible log de error
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si aún está cargando, muestra un círculo de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.primary,
          body: Column(
            children: [
              SizedBox(height: 60),
              Image.asset("assets/images/main_logo.png", width: 700),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  if (snapshot.hasData && snapshot.data != null) {
                    final user = snapshot.data!;

                    await _verifySessionTimeout(user);

                    // Revisa de nuevo si sigue logueado
                    if (FirebaseAuth.instance.currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DashboardScreen(),
                        ),
                      );
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LogInScreen()),
                    );
                  }
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(AppColors.secondary),
                  foregroundColor: WidgetStatePropertyAll(AppColors.primary),
                  fixedSize: WidgetStatePropertyAll(Size(150, 50)),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  elevation: WidgetStatePropertyAll(7),
                ),
                child: Text(
                  "EMPEZAR",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
