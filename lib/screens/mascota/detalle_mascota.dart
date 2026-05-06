import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/components/bottom_logo.dart';
import 'package:pawner_app/core/components/chat_bubble_clipper.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/app_colors.dart';


class PetProfileScreen extends StatelessWidget {
  final Mascota mascota;

  const PetProfileScreen({super.key, required this.mascota});

  int _calcularEdad(DateTime fechaNacimiento) {
    final hoy = DateTime.now();
    int edad = hoy.year - fechaNacimiento.year;
    if (hoy.month < fechaNacimiento.month ||
        (hoy.month == fechaNacimiento.month && hoy.day < fechaNacimiento.day)) {
      edad--;
    }
    return edad;
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final int edad = _calcularEdad(mascota.fechaNacimiento);

    return Scaffold(
      backgroundColor: AppColors.background, // Lavanda del dashboard
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Contenido con Padding
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          // Perfil "Unido": Avatar grande y Container de nombre pegado
                          _buildJoinedProfileHeader(edad),
                          
                          if (mascota.especie.isNotEmpty && 
                              mascota.raza.isNotEmpty && 
                              !(mascota.especie == 'Otro' && mascota.raza == 'Otro')) ...[
                            const SizedBox(height: 20),
                            _buildSpeciesBreedCard(),
                          ],
                          
                          const SizedBox(height: 40),

                          // Fila de Info Rápida con iconos del formulario
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickInfoItem(Icons.monitor_weight, "${mascota.peso} Kg", AppColors.secondary),
                              _buildQuickInfoItem(
                                mascota.genero == 'Macho' ? Icons.male : Icons.female,
                                mascota.genero,
                                mascota.genero == 'Macho' ? AppColors.male : AppColors.female,
                              ),
                              _buildQuickInfoItem(
                                LucideIcons.scissors,
                                mascota.esterilizado ? 'Esterilizado' : 'Sin Esterilizar',
                                mascota.esterilizado ? AppColors.sterilized : AppColors.notSterilized,
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),

                          // Chips de navegación usando ChatBubbleClipper
                          _buildNavigationBubbleChip(
                            title: "Comida",
                            subtitle: "Dieta y horarios",
                            icon: LucideIcons.utensils,
                            isRight: false,
                            onTap: () {
                              // TODO: Navegar a pantalla de comida
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildNavigationBubbleChip(
                            title: "Veterinario",
                            subtitle: "Cuidados y vacunas",
                            icon: LucideIcons.stethoscope,
                            isRight: true,
                            onTap: () {
                              // TODO: Navegar a pantalla de veterinario
                            },
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),
                    
                    // Footer (IGUAL al de perfil_screen, pegado al final y extremos)
                    const BottomLogo(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildJoinedProfileHeader(int edad) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Container del nombre (pegado al lateral y unido al avatar)
        Padding(
          padding: const EdgeInsets.only(left: 80),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(80, 20, 20, 20), // Aumentado padding izquierdo para alejar del avatar
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mascota.nombre,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary, // Azul oscuro
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(mascota.fechaNacimiento),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  "$edad años",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Avatar circular más grande
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 65,
            backgroundColor: Colors.white,
            backgroundImage: mascota.fotoUrl.isNotEmpty
                ? (mascota.fotoUrl.startsWith('http')
                    ? NetworkImage(mascota.fotoUrl)
                    : AssetImage(mascota.fotoUrl) as ImageProvider)
                : null,
            child: mascota.fotoUrl.isEmpty
                ? const Icon(LucideIcons.dog, size: 60, color: Colors.grey)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeciesBreedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.fingerprint, color: AppColors.secondary, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Especie y Raza",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                  ),
                ),
                Text(
                  "${mascota.especie} - ${mascota.raza}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBubbleChip({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isRight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: PhysicalShape(
        clipper: ChatBubbleClipper(isRight: isRight),
        color: AppColors.homeScreenOrange,
        elevation: 4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.homeScreenOrange, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: Colors.white, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
