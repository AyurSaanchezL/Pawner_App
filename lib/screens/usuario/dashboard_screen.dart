import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/constants.dart'; // Assuming Constants might have styles or enums
import 'package:pawner_app/screens/usuario/nueva_mascota_screen.dart'; // Keep this for the FAB logic if needed
import 'package:pawner_app/screens/usuario/ajustes_screen.dart'; // For settings navigation
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawner_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/model/usuario.dart' show Usuario;


import 'package:pawner_app/core/model/familia.dart';
import 'package:pawner_app/core/components/invitation_share_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Placeholder data for pets
  final List<Map<String, dynamic>> _petsPlaceholder = [
    {'name': 'Buddy', 'image': 'assets/images/fotos_perfil/zorro.png'}, // Placeholder image path
    {'name': 'Luna', 'image': 'assets/images/fotos_perfil/gato1.png'}, // Placeholder image path
    {'name': 'Max', 'image': 'assets/images/fotos_perfil/conejo1.png'}, // Placeholder image path
  ];

  // Placeholder data for reminders
  final List<Map<String, dynamic>> _remindersPlaceholder = [
    {'date': '21/10/25', 'name': 'Veterinario Perro 1'},
    {'date': '23/10/25', 'name': 'Vacuna Gato 1'},
    {'date': '25/10/25', 'name': 'Peluquería Perro 2'},
    {'date': '28/10/25', 'name': 'Cita Anual Perro 1'},
  ];

  // Custom colors TODO cambiar de lugar a App Colors
  final Color _scaffoldBackgroundColor = const Color(0xFFFFFDF0); // Creamy white
  final Color _darkBlue = AppColors.secondary; // Dark blue
  final Color _lightLavender = const Color(0xFFC5B4E3); // Light lavender
  final Color _pastelOrange = const Color(0xFFFFCC80); // Pastel orange/peach
  final Color _textColorPrimary = Colors.black87;
  final Color _textColorSecondary = Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBackgroundColor,
      appBar: _buildCustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mascota Section
                  _buildSectionHeader('Mascotas', _darkBlue),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _lightLavender,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          ..._petsPlaceholder.map((pet) => _buildPetPlaceholder(pet['name'], pet['image'])).toList(),
                          const SizedBox(width: 15),
                          _buildNewPetButton(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Recordatorios Section
                  _buildSectionHeader('Próximos recordatorios', _darkBlue, showListIcon: true),
                  const SizedBox(height: 15),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(), // Prevent nested scrolling issues
                    itemCount: _remindersPlaceholder.length,
                    itemBuilder: (context, index) {
                      return _buildReminderCard(_remindersPlaceholder[index]);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40), // Spacer before footer
          ],
        ),
      ),
      // Footer
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // Adjust padding as needed
        child: FutureBuilder<String>(
          future: obtenerNombreFamilia(), // Call the async function here
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Loading family name...'); // Placeholder while loading
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}'); // Show error if any
            } else {
              // Display the family name once loaded
              return Text(
                snapshot.data ?? "Sin nombre",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _textColorPrimary,
                ),
              );
            }
          },
        ),
      ),
      // Floating Action Button (migrated from original DashboardScreen)
    );
  }
  // --- App Bar ---
  PreferredSizeWidget _buildCustomAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          // TODO: Implement navigation logic for back button
          Navigator.pop(context); // Example: navigate back
        },
      ),
      title: _buildLogoTitle(),
      titleSpacing: 0, // Adjust spacing if needed
      actions: [
        _buildAppBarActions(),
      ],
    );
  }

  Widget _buildLogoTitle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pawner',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _textColorPrimary,
          ),
        ),
        Text(
          'WE <3 MASCOTAS',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: _textColorSecondary,
          ),
        ),
      ],
    );
  }

  void _showInvitationSheet() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final FirestoreService fs = FirestoreService();
    final usuario = await fs.getCurrentUser(u);
    final familia = await fs.getFamilia(usuario.familiaID ?? "");

    if (familia != null && mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => InvitationShareSheet(codigoInvitacion: familia.codigoInvitacion),
      );
    }
  }

  Widget _buildAppBarActions() {
    return Container(
      margin: const EdgeInsets.only(right: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _showInvitationSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _darkBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.userPlus, color: _darkBlue, size: 18),
                  const SizedBox(width: 5),
                  Text(
                    'Invitar',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _darkBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
            icon: Icon(LucideIcons.settings, color: _darkBlue, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AjustesScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey, // Placeholder for profile image
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // --- Section Widgets ---
  Widget _buildSectionHeader(String title, Color color, {bool showListIcon = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (showListIcon)
          Icon(LucideIcons.list, color: color),
      ],
    );
  }

  Widget _buildPetPlaceholder(String name, String imagePath) {
    return Padding(
      padding: const EdgeInsets.only(right: 15.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white, // Background for the circle image placeholder
              // Consider using Image.asset(imagePath, fit: BoxFit.cover) if images are available
              image: DecorationImage(
                image: AssetImage(imagePath), // Placeholder image
                fit: BoxFit.cover,
              ),
              border: Border.all(color: _darkBlue, width: 2),
            ),
            // child: ClipOval( // If using placeholder image directly inside container
            //   child: Image.asset(imagePath, fit: BoxFit.cover),
            // ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _textColorPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPetButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NuevaMascotaScreen()),
        );
      },
      child: Container(
        width: 80, // Slightly larger to accommodate text below
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(Icons.add, size: 40, color: Colors.black),
            ),
            const SizedBox(height: 8),
            Text(
              "Nuevo integrante",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _textColorPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    return Card(
      color: _pastelOrange,
      margin: const EdgeInsets.only(bottom: 15.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                reminder['date'],
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textColorPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                reminder['name'],
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textColorPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Revisar este codigo
// Fue hecho de manera rapida para el ejemplo, solo obtiene el nombre de la familia del usuario actual
Future<String> obtenerNombreFamilia() async {
  final u = FirebaseAuth.instance.currentUser;
  final FirestoreService _fs = FirestoreService();
  Usuario usuario = await _fs.getCurrentUser(u!);
  var famDoc = await FirebaseFirestore.instance.collection('Familias').doc(usuario.familiaID).get();

  return famDoc.data()?['nombre'] ?? "Sin nombre";
}