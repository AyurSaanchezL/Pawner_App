import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/constants.dart';

class CrearFamiliaLayout extends StatelessWidget {
  const CrearFamiliaLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightSecondary,
      body: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Nombre de familia",
              style: TextStyle(fontSize: 20, fontWeight: .w700),
            ),
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 300,
              child: TextField(
                style: Constants.inputStyle,
                maxLines: 1,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 8,
                  ),
                  hint: Text("Pawtas largas", style: Constants.inputStyle),
                  prefixIcon: Icon(Icons.pets),
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
              child: ElevatedButton(
                onPressed: () {},
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(AppColors.primary),
                  shape: WidgetStatePropertyAll(CircleBorder(eccentricity: 0)),
                  maximumSize: WidgetStatePropertyAll(Size(200, 200)),
                ),
                child: Image.asset(
                  "assets/images/logo-blanco-circulo.png",
                  width: 200,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
