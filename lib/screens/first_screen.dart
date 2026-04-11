import 'package:flutter/material.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/screens/session/log_in_screen.dart';

class FirstScreen extends StatelessWidget {
  const FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          SizedBox(height: 60),
          Image.asset("assets/images/main_logo.png", width: 700),
          SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LogInScreen()));
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(AppColors.secondary),
              foregroundColor: WidgetStatePropertyAll(AppColors.primary),
              fixedSize: WidgetStatePropertyAll(Size(150, 50)),
              shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              elevation: WidgetStatePropertyAll(7)
            ),
            child: Text("EMPEZAR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
