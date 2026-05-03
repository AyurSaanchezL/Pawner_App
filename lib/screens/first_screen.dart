import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/screens/session/log_in_screen.dart';
import 'package:pawner_app/screens/usuario/dashboard_screen.dart';
import 'package:pawner_app/services/auth_service.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    User? curUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          SizedBox(height: 60),
          Image.asset("assets/images/main_logo.png", width: 700),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              // Si aun no se ha iniciado sesión
              if (curUser == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LogInScreen()),
                );
              }
              // Sesión ya iniciada
              else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              }
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(AppColors.secondary),
              foregroundColor: WidgetStatePropertyAll(AppColors.primary),
              fixedSize: WidgetStatePropertyAll(Size(150, 50)),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
  }
}
