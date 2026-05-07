import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/screens/usuario/dashboard_screen.dart';
import 'package:pawner_app/services/auth_service.dart';
import 'package:pawner_app/services/firestore_service.dart';

class CrearFamiliaLayout extends StatefulWidget {
  const CrearFamiliaLayout({super.key});

  @override
  State<CrearFamiliaLayout> createState() => _CrearFamiliaLayoutState();
}

class _CrearFamiliaLayoutState extends State<CrearFamiliaLayout> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _crearFamilia() async {
    final nombre = _controller.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Introduce un nombre para tu familia")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Usuario usuarioActual = await authService.value.getCurrentUser();
      await FirestoreService().crearFamilia(nombre, usuarioActual);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Familia creada con éxito!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      log("Error en creación: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.pets_rounded, size: 80, color: AppColors.accent),
            const SizedBox(height: 20),
            const Text(
              "Crear tu Familia",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Dale un nombre especial a tu grupo para empezar a gestionar a tus mascotas juntos.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.dark,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    style: const TextStyle(fontSize: 18, color: AppColors.dark),
                    decoration: InputDecoration(
                      hintText: "Ej: Familia Pawsome",
                      prefixIcon: const Icon(
                        LucideIcons.pencil,
                        color: AppColors.accent,
                      ),
                      fillColor: AppColors.primary,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: AppColors.secondary,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const CircularProgressIndicator(color: AppColors.accent)
                      : ElevatedButton(
                          onPressed: _crearFamilia,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.complementary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              //     side: const BorderSide(color: AppColors.secondary, width: 1),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "CREAR FAMILIA",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
