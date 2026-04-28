import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';

class BottomLogo extends StatelessWidget {
  const BottomLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(175),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(100),
          topRight: Radius.circular(100),
        ),
      ),
      child: Transform.scale(
        scale: 2.25,
        child: Image.asset("assets/images/logo_grande_naranja.png", width: 50),
      ),
    );
  }
}
