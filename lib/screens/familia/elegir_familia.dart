import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Make sure this is imported
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/screens/familia/crear_familia.dart';
import 'package:pawner_app/screens/familia/unirse_familia.dart';

class ElegirFamiliaLayout extends StatelessWidget {
  const ElegirFamiliaLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary, // This might be overridden by the Stack
      body: SafeArea( // 1. Wrap in SafeArea
        child: Stack( // 2. Keep Stack
          fit: StackFit.expand,
          children: [
            Image.asset( // 3. Keep background image
              "assets/images/background_01.png",
              fit: BoxFit.cover, // Changed from fitWidth to cover
            ),
            Padding( // 4. Add horizontal padding to the content
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column( // 5. Use Column for header and cards
                crossAxisAlignment: CrossAxisAlignment.start, // Align header left
                children: [
                  const SizedBox(height: 40), // Space from SafeArea top

                  // Header
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
                        'Toca una opción para continuar', // Placeholder subtitle
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600], // Grayish color
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40), // Space between header and cards

                  // Interactive Cards for Join/Create
                  _buildFamilyOptionCard(
                    context: context,
                    icon: LucideIcons.users,
                    title: 'Unirse a familia',
                    subtitle: 'Tengo un código de invitación',
                    backgroundColor: AppColors.complementary.withOpacity(0.95),
                    textColor: Colors.black87, // Good contrast for complementary
                    iconColor: Colors.black87,
                    arrowColor: Colors.black87,
                    destination: const UnirseFamiliaLayout(),
                  ),
                  const SizedBox(height: 20), // Space between cards
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

                  // Spacer to push content to the top if needed, or let it fill available space
                  const Spacer(),

                  // Bottom Navigation Bar Area (if any, currently none specified, but leave room)
                  // const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build the interactive cards
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        color: backgroundColor,
        margin: EdgeInsets.zero, // Remove default Card margin if using Container padding
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            // Box shadow can be added here if Card elevation is not enough, but Card elevation usually suffices.
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
                        color: textColor.withOpacity(0.8), // Slightly lighter subtitle
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
