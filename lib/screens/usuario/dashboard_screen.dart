import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/constants.dart'; // Assuming Constants might have styles or enums
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/recordatorio.dart';
import 'package:pawner_app/screens/mascota/detalle_mascota.dart';
import 'package:pawner_app/screens/usuario/perfil_screen.dart';
import 'package:pawner_app/screens/mascota/nueva_mascota_screen.dart';
import 'package:pawner_app/screens/usuario/ajustes_screen.dart'; // For settings navigation
import 'package:pawner_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/model/usuario.dart' show Usuario;
import 'package:pawner_app/screens/first_screen.dart';

import 'package:pawner_app/core/components/invitation_share_sheet.dart';
import 'package:pawner_app/core/components/notification_permission_dialog.dart';
import 'package:pawner_app/services/notification_service.dart';

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

  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkNotificationPermission(),
    );
  }

  Future<void> _checkNotificationPermission() async {
    if (_permissionChecked) return;
    _permissionChecked = true;

    await NotificationPermissionDialog.checkAndShow(
      context,
      feature: 'los recordatorios y citas de tus mascotas',
    );
  }

  Future<void> _loadInitialData() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u != null) {
      final fs = FirestoreService();
      final usuario = await fs.getCurrentUser(u);
      dev.log(
        "Usuario: ${usuario.email} y Usuario de FirebaseAuth: ${u.email!}",
      );
      if (mounted) {
        setState(() {
          _usuarioActual = usuario;
          if (usuario.familiaID != null && usuario.familiaID!.isNotEmpty) {
            _mascotasStream = fs.streamMascotas(usuario.familiaID!);
            _recordatoriosStream = fs.streamRecordatoriosFamilia(
              usuario.familiaID!,
            );
            _sincronizarNotificaciones(usuario.familiaID!);
          }
        });
      }
      if (_usuarioActual?.familiaID != null) {
        await NotificationService().initializeForFamily(
          _usuarioActual!.familiaID!,
        );
      }
    }
  }

  Future<void> _sincronizarNotificaciones(String familiaID) async {
    final fs = FirestoreService();
    final ns = NotificationService();
    final now = DateTime.now();

    try {
      final mascotas = await fs.getMascotas(familiaID);

      for (final mascota in mascotas) {
        final citas = await fs.getCitasVeterinarias(
          mascota.familiaID,
          mascota.mascotaID,
        );

        for (final cita in citas) {
          if (!cita.notificacionActiva) continue;
          if (cita.idNotificacion == null) continue;

          final notifTime = cita.notifFechaHora ?? cita.fecha;
          if (!notifTime.isAfter(now)) continue;

          await ns
              .scheduleOneTimeNotification(
                id: cita.idNotificacion!,
                scheduledFor: notifTime,
                title: '🐾 Cita: ${mascota.nombre}',
                body: cita.motivo,
              )
              .catchError((_) {});
        }

        final horarios = await fs.getHorarios(
          mascota.familiaID,
          mascota.mascotaID,
        );

        for (final horario in horarios) {
          if (!horario.activo) {
            await ns.cancel(horario.idNotificacion).catchError((_) {});
            continue;
          }

          final parts = horario.hora.split(':');
          if (parts.length != 2) continue;

          await ns
              .scheduleFixedTimeNotification(
                id: horario.idNotificacion,
                hour: int.parse(parts[0]),
                minute: int.parse(parts[1]),
                mascotaNombre: mascota.nombre,
              )
              .catchError((_) {});
        }

        // Paseos
        final paseoConfig = await fs
            .getPaseoConfig(mascota.familiaID, mascota.mascotaID)
            .first;
        if (paseoConfig != null) {
          final count = await fs.countPaseosToday(
            mascota.familiaID,
            mascota.mascotaID,
          );
          if (count < paseoConfig.numPaseosObjetivo) {
            await ns
                .schedulePaseoReminders(
                  objetivo: paseoConfig.numPaseosObjetivo,
                  completadosHoy: count,
                  intervaloHoras: paseoConfig.intervaloRecordatoriosHoras,
                  mascotaNombre: mascota.nombre,
                )
                .catchError((_) {});
          } else {
            await ns.cancelPaseoReminders().catchError((_) {});
          }
        }

        // Higiene
        final higieneConfig = await fs.getModuloHigieneConfig(
          mascota.familiaID,
          mascota.mascotaID,
        );
        if (higieneConfig != null &&
            higieneConfig.notificacionActiva &&
            higieneConfig.idNotificacion != null &&
            higieneConfig.proximoAviso != null &&
            higieneConfig.proximoAviso!.isAfter(now)) {
          await ns
              .scheduleOneTimeNotification(
                id: higieneConfig.idNotificacion!,
                scheduledFor: higieneConfig.proximoAviso!,
                title: '🛁 Hora del baño: ${mascota.nombre}',
                body: 'Según tu rutina, hoy toca bañar a ${mascota.nombre}.',
              )
              .catchError((_) {});
        }
      }
    } catch (_) {
      // sync nunca debe bloquear ni crashear el dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double verySmallScreenWidth = 375.0;
    const double smallScreenWidth = 450.0;

    final bool isVerySmallScreen = screenWidth < verySmallScreenWidth;
    final bool isSmallScreen = screenWidth < smallScreenWidth;
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: _buildCustomAppBar(isVerySmallScreen, isSmallScreen),
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
                  StreamBuilder<List<Mascota>>(
                    stream: _mascotasStream,
                    builder: (context, mascotasSnap) {
                      final mascotas = mascotasSnap.data ?? [];
                      return StreamBuilder<List<Recordatorio>>(
                        stream: _recordatoriosStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final recordatorios = snapshot.data ?? [];

                          if (recordatorios.isEmpty) {
                            return Center(
                              child: Column(
                                children: [
                                  Icon(
                                    LucideIcons.bellOff,
                                    size: 40,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "No tienes recordatorios pendientes",
                                    style: TextStyle(
                                      fontFamily: 'Nunito',
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recordatorios.length,
                            itemBuilder: (context, index) {
                              return _buildReminderCardReal(
                                recordatorios[index],
                                mascotas,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: FutureBuilder<String>(
          future: FirestoreService().obtenerNombreFamilia(),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text(
                'Loading family name...',
                textAlign: TextAlign.center,
              );
            } else if (snapshot.hasError) {
              return Text(
                'Error: ${snapshot.error}',
                textAlign: TextAlign.center,
              );
            } else {
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
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NuevaMascotaScreen(),
              ),
            );
          },
          backgroundColor: AppColors.accent,
          child: const Icon(
            LucideIcons.plus,
            color: AppColors.cardWhite,
            size: 30,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // --- App Bar ---
  PreferredSizeWidget _buildCustomAppBar(
    bool isVerySmallScreen,
    bool isSmallScreen,
  ) {
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
      title: _buildLogoTitle(isVerySmallScreen),
      titleSpacing: 0,
      actions: [_buildAppBarActions()],
    );
  }

  Widget _buildLogoTitle(bool isVerySmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pawner',
          style: TextStyle(
            fontSize: isVerySmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textColorPrimary,
          ),
        ),
        if (!isVerySmallScreen)
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
                  // Recargamos los datos del usuario actual por si hemos hecho algún cambio
                ).then((_) {
                  _loadInitialData();
                });
              }
            },
            child: _buildUserAvatar(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar() {
    final url = _usuarioActual?.fotoUrl ?? '';
    final path = url.isNotEmpty ? FotosPerfil.getProfileImage(url) : '';
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.lightSecondary,
      backgroundImage: path.isNotEmpty ? AssetImage(path) : null,
      child: path.isEmpty
          ? const Icon(Icons.person, color: Colors.white, size: 20)
          : null,
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
        ).then((_) {
          if (_usuarioActual?.familiaID != null) {
            _sincronizarNotificaciones(_usuarioActual!.familiaID!);
          }
        });
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
                  image: mascota.fotoUrl.isEmpty
                      ? AssetImage(
                          _getDefaultAssetForMascota(mascota.mascotaID),
                        )
                      : mascota.fotoUrl.startsWith('http')
                      ? NetworkImage(mascota.fotoUrl) as ImageProvider
                      : AssetImage(mascota.fotoUrl),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: AppColors.darkBlue, width: 2),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              (mascota.nombre.length > 15
                  ? '${mascota.nombre.substring(0, 12)}...'
                  : mascota.nombre),
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

  Widget _buildReminderCardReal(Recordatorio r, List<Mascota> mascotas) {
    Mascota? mascota;
    if (r.mascotaID != null) {
      final matches = mascotas.where((m) => m.mascotaID == r.mascotaID);
      if (matches.isNotEmpty) mascota = matches.first;
    }

    final day = r.fechaHora.day.toString();
    final monthAbbr = DateFormat('MMM', 'es').format(r.fechaHora);
    final timeStr = DateFormat('HH:mm').format(r.fechaHora);

    IconData moduleIcon;
    Color moduleColor;
    switch (r.moduloID) {
      case 'mod_vet':
        moduleIcon = LucideIcons.stethoscope;
        moduleColor = AppColors.secondary;
        break;
      case 'mod_comida':
        moduleIcon = LucideIcons.utensils;
        moduleColor = Colors.orange.shade700;
        break;
      default:
        moduleIcon = LucideIcons.bell;
        moduleColor = AppColors.complementary;
    }

    final desc = r.descripcion;
    final hasDesc = desc != null && desc.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date pill
            Container(
              width: 50,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.lightSecondary.withAlpha(89),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    monthAbbr.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.black45,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 1.5,
              height: 48,
              color: AppColors.lightSecondary.withAlpha(128),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(moduleIcon, size: 13, color: moduleColor),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          r.titulo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  if (mascota != null)
                    Text(
                      mascota.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.complementary,
                      ),
                    ),
                  if (hasDesc) ...[
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 11,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
