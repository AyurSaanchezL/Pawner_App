import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/screens/familia/crear_familia.dart';
import 'package:pawner_app/screens/familia/unirse_familia.dart';

class ElegirFamiliaLayout extends StatelessWidget {
  const ElegirFamiliaLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SizedBox(
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              "assets/images/background_01.png",
              fit: BoxFit.fitWidth,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _familyButton(context, "UNIRSE", "Unirse a familia"),
                _familyButton(context, "CREAR", "Crear familia"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _familyButton(BuildContext context, String action, String text) {
    Color color = AppColors.secondary;
    Color textColor = AppColors.primary;
    if (action.startsWith("U")) {
      color = AppColors.complementary;
      textColor = AppColors.secondary;
    }

    return ElevatedButton(
      onPressed: () {
        if (action == "CREAR") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CrearFamiliaLayout()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const UnirseFamiliaLayout()),
          );
        }
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color.withAlpha(245)),
        foregroundColor: WidgetStateProperty.all(AppColors.primary),
        fixedSize: const WidgetStatePropertyAll(Size(235, 150)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        elevation: const WidgetStatePropertyAll(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
      ),
    );
  }
}
