import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/screens/familia/crear_familia.dart';
import 'package:pawner_app/screens/familia/unirse_familia.dart';

class ElegirFamiliaLayout extends StatelessWidget {
  const ElegirFamiliaLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              "assets/images/background_01.png",
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.chevronLeft,
                      color: Colors.black,
                      size: 28,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Casi listo!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca una opción para continuar',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  _buildFamilyOptionCard(
                    context: context,
                    icon: LucideIcons.users,
                    title: 'Unirse a familia',
                    subtitle: 'Tengo un código de invitación',
                    backgroundColor: AppColors.complementary.withAlpha(242),
                    textColor: Colors.black87,
                    iconColor: Colors.black87,
                    arrowColor: Colors.black87,
                    destination: const UnirseFamiliaLayout(),
                  ),
                  const SizedBox(height: 20),
                  _buildFamilyOptionCard(
                    context: context,
                    icon: LucideIcons.plusCircle,
                    title: 'Crear familia',
                    subtitle: 'Empieza tu nueva familia',
                    backgroundColor: AppColors.secondary,
                    textColor: Colors.white,
                    iconColor: Colors.white,
                    arrowColor: Colors.white,
                    destination: const CrearFamiliaLayout(),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
    required Color arrowColor,
    required Widget destination,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Card(
        elevation: 8, // Soft shadow
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        color: backgroundColor,
        margin: EdgeInsets
            .zero, // Remove default Card margin if using Container padding
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 30),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: textColor.withAlpha(
                          204,
                        ), // Slightly lighter subtitle
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: arrowColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
