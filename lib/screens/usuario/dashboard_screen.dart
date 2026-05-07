import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/constants.dart'; // Assuming Constants might have styles or enums
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/recordatorio.dart';
import 'package:pawner_app/screens/mascota/detalle_mascota.dart';
import 'package:pawner_app/screens/usuario/perfil_screen.dart';
import 'package:pawner_app/screens/mascota/nueva_mascota_screen.dart'; // Keep this for the FAB logic if needed
import 'package:pawner_app/screens/usuario/ajustes_screen.dart'; // For settings navigation
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawner_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/model/usuario.dart' show Usuario;
import 'package:pawner_app/screens/first_screen.dart';

import 'package:pawner_app/core/components/invitation_share_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Usuario? _usuarioActual;
  Stream<List<Mascota>>? _mascotasStream;
  Stream<List<Recordatorio>>? _recordatoriosStream;

  final List<String> _randomPetAssets = [
    'assets/images/fotos_perfil/buho.png',
    'assets/images/fotos_perfil/cheeta.png',
    'assets/images/fotos_perfil/ciervo.png',
    'assets/images/fotos_perfil/conejo.png',
    'assets/images/fotos_perfil/elefante.png',
    'assets/images/fotos_perfil/flamenco.png',
    'assets/images/fotos_perfil/jabali.png',
    'assets/images/fotos_perfil/jirafa.png',
    'assets/images/fotos_perfil/koala.png',
    'assets/images/fotos_perfil/lemur.png',
    'assets/images/fotos_perfil/lobo.png',
    'assets/images/fotos_perfil/mapache.png',
    'assets/images/fotos_perfil/nutria.png',
    'assets/images/fotos_perfil/oso.png',
    'assets/images/fotos_perfil/panda.png',
    'assets/images/fotos_perfil/tejon.png',
    'assets/images/fotos_perfil/tucan.png',
    'assets/images/fotos_perfil/zorro.png',
  ];

  String _getDefaultAssetForMascota(String mascotaId) {
    final index = mascotaId.hashCode.abs() % _randomPetAssets.length;
    return _randomPetAssets[index];
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      final fs = FirestoreService();
      final usuario = await fs.getCurrentUser(u);
      if (usuario.email != u.email!) {
        usuario.email = u.email!;
        await FirestoreService().updateUsuario(usuario);
      }
      if (mounted) {
        setState(() {
          _usuarioActual = usuario;
          if (usuario.familiaID != null && usuario.familiaID!.isNotEmpty) {
            _mascotasStream = fs.streamMascotas(usuario.familiaID!);
            _recordatoriosStream = fs.streamRecordatoriosFamilia(usuario.familiaID!);
          }
        });
      }
    }
  }

  // Placeholder data for reminders
  final List<Map<String, dynamic>> _remindersPlaceholder = [
    {'date': '21/10/25', 'name': 'Veterinario Perro 1'},
    {'date': '23/10/25', 'name': 'Vacuna Gato 1'},
    {'date': '25/10/25', 'name': 'Peluquería Perro 2'},
    {'date': '28/10/25', 'name': 'Cita Anual Perro 1'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: _buildCustomAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mascota Section
                  _buildSectionHeader('Mascotas', AppColors.darkBlue),
                  const SizedBox(height: 15),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.lightSecondary,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          if (_mascotasStream != null)
                            StreamBuilder<List<Mascota>>(
                              stream: _mascotasStream,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final mascotas = snapshot.data!;
                                  if (mascotas.isEmpty) {
                                    return _buildEmptyPetsPlaceholder();
                                  }
                                  return Row(
                                    children: mascotas
                                        .map(
                                          (mascota) => _buildPetItem(mascota),
                                        )
                                        .toList(),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            )
                          else
                            _buildEmptyPetsPlaceholder(),
                          const SizedBox(width: 15),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Recordatorios Section
                  _buildSectionHeader(
                    'Próximos recordatorios',
                    AppColors.darkBlue,
                    showListIcon: true,
                  ),
                  const SizedBox(height: 15),
                  if (_recordatoriosStream != null)
                    StreamBuilder<List<Recordatorio>>(
                      stream: _recordatoriosStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                "Error al cargar: ${snapshot.error}",
                                style: const TextStyle(color: Colors.red, fontFamily: 'Nunito'),
                              ),
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final recordatorios = snapshot.data!;
                        if (recordatorios.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                "No hay recordatorios próximos.",
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recordatorios.length,
                          itemBuilder: (context, index) {
                            return _buildReminderCardReal(recordatorios[index]);
                          },
                        );
                      },
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          "Inicia sesión para ver recordatorios.",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
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
        padding: const EdgeInsets.only(
          bottom: 20.0,
        ), // Adjust padding as needed
        child: FutureBuilder<String>(
          future: obtenerNombreFamilia(), // Call the async function here
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                'Loading family name...',
                textAlign: TextAlign.center,
              ); // Placeholder while loading
            } else if (snapshot.hasError) {
              return Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              ); // Show error if any
            } else {
              // Display the family name once loaded
              return Text(
                snapshot.data ?? "Sin nombre",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColorPrimary,
                ),
              );
            }
          },
        ),
      ),
      // Floating Action Button
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 10, right: 10),
        child: Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                spreadRadius: 2,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NuevaMascotaScreen(),
                ),
              );
            },
            backgroundColor: Colors.white,
            elevation: 0, // Elevation handled by Container shadow
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 40, color: Colors.black),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FirstScreen()),
          );
        },
      ),
      title: _buildLogoTitle(),
      titleSpacing: 0, // Adjust spacing if needed
      actions: [_buildAppBarActions()],
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textColorPrimary,
          ),
        ),
        Text(
          'WE <3 MASCOTAS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: AppColors.textColorSecondary,
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
        builder: (context) =>
            InvitationShareSheet(codigoInvitacion: familia.codigoInvitacion),
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
                border: Border.all(color: AppColors.darkBlue.withAlpha(75)),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.userPlus,
                    color: AppColors.darkBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Invitar',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
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
            icon: Icon(
              LucideIcons.settings,
              color: AppColors.darkBlue,
              size: 24,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AjustesScreen()),
              );
            },
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              if (_usuarioActual != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PerfilUsuarioScreen(u: _usuarioActual!),
                  ),
                );
              }
            },
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey, // Placeholder for profile image
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- Section Widgets ---
  Widget _buildSectionHeader(
    String title,
    Color color, {
    bool showListIcon = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        if (showListIcon) Icon(LucideIcons.list, color: color),
      ],
    );
  }

  Widget _buildEmptyPetsPlaceholder() {
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.dog,
            color: AppColors.darkBlue.withAlpha(167),
            size: 40,
          ),
          const SizedBox(width: 15),
          Text(
            "¡Añade a tus mascotas!",
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue.withAlpha(178),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetItem(Mascota mascota) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetProfileScreen(mascota: mascota),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 15.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                image: DecorationImage(
                  image: mascota.fotoUrl.isNotEmpty
                      ? NetworkImage(mascota.fotoUrl) as ImageProvider
                      : AssetImage(_getDefaultAssetForMascota(mascota.mascotaID)),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: AppColors.darkBlue, width: 2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mascota.nombre,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textColorPrimary,
              ),
            ),
          ],
        ),
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
      child: SizedBox(
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
                    color: Colors.black26, // Sombra más oscura
                    blurRadius: 8, // Sombra más difuminada
                    spreadRadius: 2, // Sombra más extendida
                    offset: Offset(0, 4),
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
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textColorPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    return Card(
      color: AppColors.accent,
      margin: const EdgeInsets.only(bottom: 15.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColorPrimary,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                reminder['name'],
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColorPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCardReal(Recordatorio r) {
    final dateStr =
        "${r.fechaHora.day.toString().padLeft(2, '0')}/${r.fechaHora.month.toString().padLeft(2, '0')}/${r.fechaHora.year.toString().substring(2)}";
    final timeStr =
        "${r.fechaHora.hour.toString().padLeft(2, '0')}:${r.fechaHora.minute.toString().padLeft(2, '0')}";
    return Card(
      color: r.completado ? Colors.grey.shade200 : AppColors.accent,
      margin: const EdgeInsets.only(bottom: 15.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textColorPrimary,
                    ),
                  ),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textColorSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                r.titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColorPrimary,
                  decoration: r.completado ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Checkbox(
              value: r.completado,
              onChanged: (v) {
                if (v != null && _usuarioActual?.familiaID != null) {
                  FirestoreService().toggleRecordatorioCompletado(
                    _usuarioActual!.familiaID!,
                    r.recordatorioID,
                    v,
                  );
                }
              },
              activeColor: AppColors.secondary,
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
  final FirestoreService fs = FirestoreService();
  Usuario usuario = await fs.getCurrentUser(u!);
  var famDoc = await FirebaseFirestore.instance
      .collection('Familias')
      .doc(usuario.familiaID)
      .get();

  return famDoc.data()?['nombre'] ?? "Sin nombre";
}
