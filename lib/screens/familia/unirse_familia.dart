import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/screens/usuario/dashboard_screen.dart';
import 'package:pawner_app/services/auth_service.dart';
import 'package:pawner_app/services/firestore_service.dart';

class UnirseFamiliaLayout extends StatefulWidget {
  const UnirseFamiliaLayout({super.key});

  @override
  State<UnirseFamiliaLayout> createState() => _UnirseFamiliaLayoutState();
}

class _UnirseFamiliaLayoutState extends State<UnirseFamiliaLayout> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _unirseAFamilia() async {
    final codigo = _controller.text.trim().toUpperCase();
    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Introduce el código de invitación")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Usuario usuarioActual = await authService.value.getCurrentUser();
      String? error = await FirestoreService().unirseAFamilia(
        codigo,
        usuarioActual,
      );

      if (mounted) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.orange),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("¡Te has unido a la familia!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      log("Error al unirse: $e");
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
            const Icon(LucideIcons.users, size: 80, color: AppColors.secondary),
            const SizedBox(height: 20),
            const Text(
              "Unirse a una Familia",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
                fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Introduce el código de 6 dígitos para conectarte con tus seres queridos y sus mascotas.",
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
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                      color: AppColors.accent,
                    ),
                    decoration: InputDecoration(
                      hintText: "000000",
                      hintStyle: TextStyle(
                        color: Colors.grey[300],
                        letterSpacing: 10,
                      ),
                      counterText: "",
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
                      ? const CircularProgressIndicator(
                          color: AppColors.secondary,
                        )
                      : ElevatedButton(
                          onPressed: _unirseAFamilia,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            "UNIRSE",
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
