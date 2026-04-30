import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/constants.dart';
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
    final codigo = _controller.text.trim();
    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Introduce el código de invitación")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Usuario usuarioActual = await authService.value.getCurrentUser();

      // Llamamos al servicio para unirnos
      String? error = await FirestoreService().unirseAFamilia(codigo, usuarioActual);

      if (mounted) {
        if (error != null) {
          // Si el servicio devuelve un mensaje, es que el código no existe
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.orange),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("¡Te has unido a la familia!"), backgroundColor: Colors.green),
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
      backgroundColor: AppColors.lightSecondary,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Código de familia",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 300,
              child: TextField(
                controller: _controller,
                style: Constants.inputStyle,
                maxLines: 1,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 8,
                  ),
                  hintText: "Ej: XF45-GP12",
                  hintStyle: Constants.inputStyle,
                  prefixIcon: const Icon(Icons.vpn_key),
                  fillColor: AppColors.primary,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _unirseAFamilia,
                style: ButtonStyle(
                  backgroundColor: const WidgetStatePropertyAll(AppColors.primary),
                  shape: const WidgetStatePropertyAll(CircleBorder(eccentricity: 0)),
                  maximumSize: const WidgetStatePropertyAll(Size(200, 200)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 100,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
