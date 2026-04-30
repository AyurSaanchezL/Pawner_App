import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text("Dashboard", style: TextStyle(color: AppColors.primary)),
        backgroundColor: AppColors.secondary,
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          "¡Bienvenido a tu Dashboard!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.dark),
        ),
      ),
    );
  }
}
