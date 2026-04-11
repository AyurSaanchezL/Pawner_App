import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';

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
                _familyButton("UNIRSE", "Unirse a familia"),
                _familyButton("CREAR", "Crear familia"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _familyButton(String action, String text) {
    Color color = AppColors.secondary;
    Color textColor = AppColors.primary;
    if (action.startsWith("U")) {
      color = AppColors.complementary;
      textColor = AppColors.secondary;
    }

    return ElevatedButton(
      onPressed: () {
        
      },
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(color.withAlpha(245)),
        foregroundColor: WidgetStateProperty.all(AppColors.primary),
        fixedSize: WidgetStatePropertyAll(Size(235, 150)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(10),
          ),
        ),
        elevation: WidgetStatePropertyAll(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 20, fontWeight: .w800, color: textColor),
      ),
    );
  }
}
