import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/components/notification_permission_dialog.dart';
import 'package:pawner_app/core/model/modulo_vet/cita_veterinaria.dart';
import 'package:pawner_app/core/model/modulo_vet/evento_salud.dart';
import 'package:pawner_app/core/model/modulo_vet/modulo_vet_config.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/services/firestore_service.dart';
import 'package:pawner_app/services/notification_service.dart';
import 'package:pawner_app/services/cloudinary_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

enum NotifTiming {
  horasBefore1,
  horasBefore5,
  diaBefore,
  semanaBefore,
  personalizado,
}

DateTime? computeNotifDateTime(
  NotifTiming timing,
  DateTime citaDateTime, {
  DateTime? custom,
}) {
  switch (timing) {
    case NotifTiming.horasBefore1:
      return citaDateTime.subtract(const Duration(hours: 1));
    case NotifTiming.horasBefore5:
      return citaDateTime.subtract(const Duration(hours: 5));
    case NotifTiming.diaBefore:
      return citaDateTime.subtract(const Duration(days: 1));
    case NotifTiming.semanaBefore:
      return citaDateTime.subtract(const Duration(days: 7));
    case NotifTiming.personalizado:
      return custom;
  }
}

class _VetEntry {
  final TextEditingController nombreCtrl;
  final TextEditingController telCtrl;
  final TextEditingController colegiadoCtrl;

  _VetEntry({String nombre = '', String tel = '', String colegiado = ''})
    : nombreCtrl = TextEditingController(text: nombre),
      telCtrl = TextEditingController(text: tel),
      colegiadoCtrl = TextEditingController(text: colegiado);

  void dispose() {
    nombreCtrl.dispose();
    telCtrl.dispose();
    colegiadoCtrl.dispose();
  }
}

class VeterinarioScreen extends StatefulWidget {
  final Mascota mascota;

  const VeterinarioScreen({super.key, required this.mascota});

  @override
  State<VeterinarioScreen> createState() => _VeterinarioScreenState();
}

class _VeterinarioScreenState extends State<VeterinarioScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();
  final NotificationService _notifications = NotificationService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationPermissionDialog.checkAndShow(
        context,
        feature: 'las citas veterinarias y recordatorios de tus mascotas',
      );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleNotificacion(CitaVeterinaria cita, bool value, Mascota mascota) {
    if (value) {
      final notifTime = cita.notifFechaHora;
      if (notifTime == null || !notifTime.isAfter(DateTime.now())) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No es posible activar el aviso: la fecha del recordatorio ya ha pasado.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() => cita.notificacionActiva = true);
      _fs.updateCitaVeterinaria(mascota.familiaID, mascota.mascotaID, cita);
      if (cita.idNotificacion != null) {
        _notifications
            .scheduleOneTimeNotification(
              id: cita.idNotificacion!,
              scheduledFor: notifTime,
              title: '🐾 Cita: ${mascota.nombre}',
              body: cita.motivo,
            )
            .catchError((_) {});
      }
    } else {
      setState(() => cita.notificacionActiva = false);
      _fs.updateCitaVeterinaria(mascota.familiaID, mascota.mascotaID, cita);
      if (cita.idNotificacion != null) {
        _notifications.cancel(cita.idNotificacion!);
      }
    }
  }

  void _eliminarCita(CitaVeterinaria cita, Mascota mascota) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Eliminar Cita",
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "¿Estás seguro de que quieres eliminar esta cita?",
          style: TextStyle(fontFamily: 'Nunito'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(fontFamily: 'Nunito', color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              if (cita.recordatorioID != null) {
                _fs.deleteCitaVeterinariaWithReminder(
                  mascota.familiaID,
                  mascota.mascotaID,
                  cita.id,
                  cita.recordatorioID!,
                );
              } else {
                _fs.deleteCitaVeterinaria(
                  mascota.familiaID,
                  mascota.mascotaID,
                  cita.id,
                );
              }
              if (cita.idNotificacion != null) {
                _notifications.cancel(cita.idNotificacion!);
              }
              Navigator.pop(context);
            },
            child: const Text(
              "Eliminar",
              style: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _eliminarEvento(String eventoId, Mascota mascota) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Eliminar Evento",
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "¿Estás seguro de que quieres eliminar este evento?",
          style: TextStyle(fontFamily: 'Nunito'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(fontFamily: 'Nunito', color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              _fs.deleteEventoSalud(
                mascota.familiaID,
                mascota.mascotaID,
                eventoId,
              );
              Navigator.pop(context);
            },
            child: const Text(
              "Eliminar",
              style: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGETS DE UI ---

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Mascota>(
      stream: _fs.streamMascota(
        widget.mascota.familiaID,
        widget.mascota.mascotaID,
      ),
      builder: (context, snapshotMascota) {
        final currentMascota = snapshotMascota.data ?? widget.mascota;

        return Scaffold(
          backgroundColor: AppColors.homeScreenBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(
                LucideIcons.chevronLeft,
                color: Colors.black,
                size: 30,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.lightSecondary.withAlpha(70),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.stethoscope,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Salud · ${currentMascota.nombre}",
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.secondary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.secondary,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: "Citas"),
                Tab(text: "Historial"),
                Tab(text: "Perfil"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildCitasTab(currentMascota),
              _buildHistorialTab(currentMascota),
              _buildPerfilTab(currentMascota),
            ],
          ),
          floatingActionButton: AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              if (_tabController.index == 2) return const SizedBox.shrink();
              return FloatingActionButton(
                onPressed: () {
                  if (_tabController.index == 0) {
                    _showAddCitaSheet(currentMascota);
                  } else {
                    _showAddEventoSheet(currentMascota);
                  }
                },
                backgroundColor: AppColors.homeScreenOrange,
                child: const Icon(LucideIcons.plus, color: Colors.white),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildCitasTab(Mascota currentMascota) {
    return StreamBuilder<List<CitaVeterinaria>>(
      stream: _fs.streamCitasVeterinarias(
        currentMascota.familiaID,
        currentMascota.mascotaID,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final citas = snapshot.data!.where((c) => !c.completada).toList();

        if (citas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.calendarCheck,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  "¡Todo en orden!\nNo tienes visitas pendientes.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          itemCount: citas.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  "Próximas citas · ${citas.length}",
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              );
            }
            return _buildCitaCard(citas[index - 1], currentMascota);
          },
        );
      },
    );
  }

  void _showCitaDetailSheet(CitaVeterinaria cita, Mascota currentMascota) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          CitaDetailSheet(cita: cita, mascota: currentMascota),
    );
  }

  Widget _buildCitaCard(CitaVeterinaria cita, Mascota currentMascota) {
    return GestureDetector(
      onTap: () => _showCitaDetailSheet(cita, currentMascota),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge de fecha
                  Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.lightSecondary.withAlpha(60),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${cita.fecha.day}',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: AppColors.secondary,
                          ),
                        ),
                        Text(
                          DateFormat('MMM').format(cita.fecha).toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 10,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Contenido
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cita.motivo,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.clock4,
                              size: 13,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('HH:mm').format(cita.fecha),
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        if (cita.veterinario != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.mapPin,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  cita.veterinario!,
                                  style: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Marcar completada
                  IconButton(
                    icon: Icon(
                      LucideIcons.checkCircle,
                      color: Colors.green.shade400,
                      size: 26,
                    ),
                    onPressed: () {
                      cita.completada = true;
                      _fs.updateCitaVeterinaria(
                        currentMascota.familiaID,
                        currentMascota.mascotaID,
                        cita,
                      );
                      if (cita.recordatorioID != null) {
                        _fs.toggleRecordatorioCompletado(
                          currentMascota.familiaID,
                          cita.recordatorioID!,
                          true,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            // Franja inferior: recordatorio + eliminar
            Container(
              decoration: BoxDecoration(
                color: AppColors.homeScreenBackground,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        cita.notificacionActiva
                            ? LucideIcons.bell
                            : LucideIcons.bellOff,
                        size: 14,
                        color: cita.notificacionActiva
                            ? AppColors.secondary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cita.notificacionActiva
                            ? "Recordatorio activo"
                            : "Sin aviso",
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 12,
                          color: cita.notificacionActiva
                              ? AppColors.secondary
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: cita.notificacionActiva,
                          onChanged: (v) =>
                              _toggleNotificacion(cita, v, currentMascota),
                          activeThumbColor: AppColors.secondary,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      InkWell(
                        onTap: () => _eliminarCita(cita, currentMascota),
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            LucideIcons.trash2,
                            color: Colors.redAccent,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCitaSheet(Mascota currentMascota) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddCitaSheet(
        mascota: currentMascota,
        onSaved: () => Navigator.pop(context),
      ),
    );
  }

  void _showAddEventoSheet(Mascota currentMascota) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddEventoSheet(
        mascota: currentMascota,
        onSaved: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildHistorialTab(Mascota currentMascota) {
    return StreamBuilder<List<EventoSalud>>(
      stream: _fs.streamEventosSalud(
        currentMascota.familiaID,
        currentMascota.mascotaID,
      ),
      builder: (context, snapshotEv) {
        return StreamBuilder<List<CitaVeterinaria>>(
          stream: _fs.streamCitasVeterinarias(
            currentMascota.familiaID,
            currentMascota.mascotaID,
          ),
          builder: (context, snapshotCi) {
            if (!snapshotEv.hasData || !snapshotCi.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final eventos = snapshotEv.data!;
            final citasCompletadas = snapshotCi.data!
                .where((c) => c.completada)
                .toList();

            // Combinar y ordenar por fecha descendente
            final List<dynamic> items = [...eventos, ...citasCompletadas];
            items.sort((a, b) {
              final dateA = a is EventoSalud
                  ? a.fecha
                  : (a as CitaVeterinaria).fecha;
              final dateB = b is EventoSalud
                  ? b.fecha
                  : (b as CitaVeterinaria).fecha;
              return dateB.compareTo(dateA);
            });

            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.history,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No hay historial registrado.",
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      "Historial de salud · ${items.length}",
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  );
                }
                final item = items[index - 1];
                final bool isEvento = item is EventoSalud;
                return InkWell(
                  onTap: () {
                    if (!isEvento) {
                      _showCitaDetailSheet(
                        item as CitaVeterinaria,
                        currentMascota,
                      );
                    }
                  },
                  child: _buildTimelineItem(item, isEvento, currentMascota),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineItem(
    dynamic item,
    bool isEvento,
    Mascota currentMascota,
  ) {
    final String titulo = isEvento
        ? (item as EventoSalud).tipo
        : (item as CitaVeterinaria).motivo;
    final String desc = isEvento
        ? (item as EventoSalud).descripcion
        : (item as CitaVeterinaria).notas ?? "Cita completada";
    final DateTime fecha = isEvento
        ? (item as EventoSalud).fecha
        : (item as CitaVeterinaria).fecha;
    final String? imgUrl = isEvento ? (item as EventoSalud).adjuntoUrl : null;
    final String id = isEvento
        ? (item as EventoSalud).id
        : (item as CitaVeterinaria).id;

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(child: Container(width: 2, color: Colors.grey.shade300)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd MMM yyyy').format(fecha),
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              titulo,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                if (!isEvento)
                                  const Icon(
                                    LucideIcons.checkCircle,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    size: 16,
                                    color: Colors.redAccent,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    if (isEvento) {
                                      _eliminarEvento(id, currentMascota);
                                    } else {
                                      _eliminarCita(
                                        item as CitaVeterinaria,
                                        currentMascota,
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          desc,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                        if (imgUrl != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imgUrl,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPerfilSheet(ModuloVetConfig? config, Mascota currentMascota) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditPerfilSheet(
        mascota: currentMascota,
        config: config,
        onSaved: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildPerfilTab(Mascota currentMascota) {
    return StreamBuilder<ModuloVetConfig?>(
      stream: _fs.streamModuloVetConfig(
        currentMascota.familiaID,
        currentMascota.mascotaID,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());

        final config = snapshot.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMascotaHeaderCard(currentMascota),
              const SizedBox(height: 24),
              _buildSectionHeader(
                "Información Crítica",
                () => _showEditPerfilSheet(config, currentMascota),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      "Peso Actual",
                      "${currentMascota.peso} kg",
                      LucideIcons.scale,
                    ),
                  ),
                  if (config?.seguroMedico?.isNotEmpty == true) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        "Seguro",
                        config!.seguroMedico!,
                        LucideIcons.shieldCheck,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              _buildAlergiasCard(config?.alergias ?? []),
              const SizedBox(height: 30),
              _buildSectionHeader("Contacto Veterinario", null),
              const SizedBox(height: 16),
              _buildVeteCard(config),
              const SizedBox(height: 40),
              _buildEmergencyButton(config?.telUrgencias),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMascotaHeaderCard(Mascota mascota) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.lightSecondary.withAlpha(77),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.stethoscope,
              color: AppColors.secondary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mascota.nombre,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  '${mascota.especie} · ${mascota.raza}',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${mascota.peso} kg',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.secondary,
                ),
              ),
              const Text(
                'peso actual',
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback? onEdit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        if (onEdit != null)
          IconButton(
            icon: const Icon(
              LucideIcons.edit3,
              color: AppColors.secondary,
              size: 20,
            ),
            onPressed: onEdit,
          ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondary, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlergiasCard(List<String> alergias) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                "Alergias y Contraindicaciones",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (alergias.isEmpty)
            const Text(
              "Sin alergias registradas",
              style: TextStyle(fontFamily: 'Nunito', color: Colors.grey),
            )
          else
            Wrap(
              spacing: 8,
              children: alergias
                  .map(
                    (a) => Chip(
                      label: Text(
                        a,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: Colors.redAccent.withAlpha(204),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildVeteCard(ModuloVetConfig? config) {
    final vetes = config?.veterinarios ?? [];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10),
        ],
      ),
      child: vetes.isEmpty
          ? const Text(
              "Sin veterinarios registrados",
              style: TextStyle(fontFamily: 'Nunito', color: Colors.grey),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < vetes.length; i++) ...[
                  if (i > 0) const Divider(height: 24),
                  _buildVetEntry(vetes[i]),
                ],
              ],
            ),
    );
  }

  Widget _buildVetEntry(Map<String, String> vet) {
    final nombre = vet['nombre'] ?? '';
    final tel = vet['telefono'] ?? '';
    final colegiado = vet['numColegiado'] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nombre.isNotEmpty) _buildVeteRow(Icons.local_hospital, nombre),
        if (tel.isNotEmpty) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              final uri = Uri.parse('tel:${tel.replaceAll(' ', '')}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              child: Row(
                children: [
                  Icon(LucideIcons.phone, size: 20, color: AppColors.secondary),
                  const SizedBox(width: 12),
                  Text(
                    tel,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (colegiado.isNotEmpty) ...[
          const SizedBox(height: 10),
          _buildVeteRow(LucideIcons.userCheck, 'Colegiado: $colegiado'),
        ],
      ],
    );
  }

  Widget _buildVeteRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.secondary),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyButton(String? tel) {
    return SizedBox(
      width: double.infinity,
      height: 70,
      child: ElevatedButton.icon(
        onPressed: () async {
          if (tel != null && tel.isNotEmpty) {
            final Uri url = Uri.parse("tel:${tel.replaceAll(' ', '')}");
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("No se pudo iniciar la llamada a $tel")),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Teléfono de urgencias no configurado"),
              ),
            );
          }
        },
        icon: const Icon(LucideIcons.phoneCall, color: Colors.white, size: 28),
        label: const Text(
          "LLAMAR URGENCIAS",
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          shadowColor: Colors.redAccent.withAlpha(128),
        ),
      ),
    );
  }
}

class _AddEventoSheet extends StatefulWidget {
  final Mascota mascota;
  final VoidCallback onSaved;

  const _AddEventoSheet({required this.mascota, required this.onSaved});

  @override
  State<_AddEventoSheet> createState() => _AddEventoSheetState();
}

class _AddEventoSheetState extends State<_AddEventoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  String _tipo = 'Vacuna';
  DateTime _fecha = DateTime.now();
  File? _image;
  bool _isUploading = false;

  final List<String> _tipos = [
    'Vacuna',
    'Desparasitación',
    'Diagnóstico',
    'Cirugía',
    'Control',
    'Otro',
  ];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    String? imageUrl;
    if (_image != null) {
      imageUrl = await CloudinaryService().uploadImage(_image!);
    }

    final evento = EventoSalud(
      id: '',
      tipo: _tipo,
      descripcion: _descController.text.trim(),
      fecha: _fecha,
      adjuntoUrl: imageUrl,
    );

    await FirestoreService().addEventoSalud(
      widget.mascota.familiaID,
      widget.mascota.mascotaID,
      evento,
    );

    setState(() => _isUploading = false);
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Nuevo Evento de Salud",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Tipo de evento",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 45,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _tipos
                      .map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              t,
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: _tipo == t ? Colors.white : Colors.black,
                              ),
                            ),
                            selected: _tipo == t,
                            onSelected: (val) => setState(() => _tipo = t),
                            selectedColor: AppColors.secondary,
                            backgroundColor: AppColors.inputBackground
                                .withAlpha(100),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: "Descripción (ej: Vacuna de la rabia)",
                  filled: true,
                  fillColor: AppColors.inputBackground.withAlpha(100),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? "Campo obligatorio" : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _fecha,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365 * 5),
                    ),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _fecha = d);
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground.withAlpha(100),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        size: 18,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('dd/MM/yyyy').format(_fecha),
                        style: const TextStyle(fontFamily: 'Nunito'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Adjuntar foto (receta, carnet...)",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground.withAlpha(50),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: AppColors.secondary.withAlpha(50),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _image != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(_image!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.camera,
                              color: AppColors.secondary,
                            ),
                            Text(
                              "Añadir imagen",
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Guardar en Historial",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class AddCitaSheet extends StatefulWidget {
  final Mascota mascota;
  final VoidCallback onSaved;
  final FirestoreService? fsOverride;

  const AddCitaSheet({
    required this.mascota,
    required this.onSaved,
    this.fsOverride,
  });

  @override
  State<AddCitaSheet> createState() => _AddCitaSheetState();
}

class _AddCitaSheetState extends State<AddCitaSheet> {
  FirestoreService get _fs => widget.fsOverride ?? FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _veterinarioController = TextEditingController();
  final _notasController = TextEditingController();
  DateTime _fecha = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _hora = const TimeOfDay(hour: 10, minute: 0);
  bool _notificacionActiva = true;
  bool _isLoading = false;
  NotifTiming _notifTiming = NotifTiming.diaBefore;
  DateTime? _customNotifDateTime;
  ModuloVetConfig? _vetConfig;

  @override
  void initState() {
    super.initState();
    _fs
        .getModuloVetConfig(widget.mascota.familiaID, widget.mascota.mascotaID)
        .then((c) {
          if (mounted) setState(() => _vetConfig = c);
        });
  }

  String _timingLabel(NotifTiming t) {
    switch (t) {
      case NotifTiming.horasBefore1:
        return '1h antes';
      case NotifTiming.horasBefore5:
        return '5h antes';
      case NotifTiming.diaBefore:
        return '1 día antes';
      case NotifTiming.semanaBefore:
        return '1 semana antes';
      case NotifTiming.personalizado:
        return 'Personalizado';
    }
  }

  DateTime? _computeNotifDateTime() {
    final citaDateTime = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _hora.hour,
      _hora.minute,
    );
    return computeNotifDateTime(
      _notifTiming,
      citaDateTime,
      custom: _customNotifDateTime,
    );
  }

  Future<void> _pickCustomNotifDateTime() async {
    final citaDateTime = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _hora.hour,
      _hora.minute,
    );
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: citaDateTime,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;
    setState(() {
      _customNotifDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final fechaHora = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _hora.hour,
      _hora.minute,
    );

    // Calcular cuándo se disparará la notificación
    DateTime? notifDateTime;
    if (_notificacionActiva) {
      notifDateTime = _computeNotifDateTime();
      if (notifDateTime != null && !notifDateTime.isAfter(DateTime.now())) {
        notifDateTime = null; // ya pasó, no se programa
      }
    }

    // idNotif solo se genera si hay un momento válido para el aviso
    final int? idNotif = (_notificacionActiva && notifDateTime != null)
        ? DateTime.now().millisecondsSinceEpoch % 100000
        : null;

    // Cuerpo de la notificación
    final motivo = _motivoController.text.trim();
    final notas = _notasController.text.trim();
    final notifBody = notas.isNotEmpty
        ? '$motivo · ${notas.length > 60 ? '${notas.substring(0, 60)}…' : notas}'
        : motivo;

    final cita = CitaVeterinaria(
      id: '',
      fecha: fechaHora,
      motivo: motivo,
      veterinario: _veterinarioController.text.trim().isEmpty
          ? null
          : _veterinarioController.text.trim(),
      notas: notas.isEmpty ? null : notas,
      notificacionActiva: _notificacionActiva && notifDateTime != null,
      idNotificacion: idNotif,
      notifFechaHora: notifDateTime,
    );

    try {
      await _fs.addCitaVeterinaria(
        widget.mascota.familiaID,
        widget.mascota.mascotaID,
        cita,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error al agendar la cita. Inténtalo de nuevo."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_notificacionActiva && idNotif != null && notifDateTime != null) {
      NotificationService()
          .scheduleOneTimeNotification(
            id: idNotif,
            scheduledFor: notifDateTime,
            title: '🐾 Cita: ${widget.mascota.nombre}',
            body: notifBody,
          )
          .catchError((_) {});
    }

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    widget.onSaved();

    final msg = (_notificacionActiva && notifDateTime == null)
        ? '¡Cita agendada! El recordatorio no se programó (fecha ya pasada)'
        : '¡Cita agendada con éxito!';
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Nueva Cita",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 20),
              _buildInput(
                "Motivo (ej: Vacuna, Revisión)",
                _motivoController,
                isRequired: true,
              ),
              const SizedBox(height: 16),
              _buildInput("Clínica / Veterinario", _veterinarioController),
              if (_vetConfig != null &&
                  _vetConfig!.veterinarios.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final vet in _vetConfig!.veterinarios)
                      ActionChip(
                        avatar: const Icon(Icons.local_hospital, size: 14),
                        label: Text(
                          vet['nombre'] ?? '',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                          ),
                        ),
                        onPressed: () => setState(
                          () =>
                              _veterinarioController.text = vet['nombre'] ?? '',
                        ),
                        backgroundColor: AppColors.lightSecondary.withAlpha(80),
                        side: BorderSide.none,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSelector(
                      LucideIcons.calendar,
                      DateFormat('dd/MM/yyyy').format(_fecha),
                      () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _fecha,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (d != null) setState(() => _fecha = d);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSelector(
                      LucideIcons.clock,
                      _hora.format(context),
                      () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: _hora,
                        );
                        if (t != null) setState(() => _hora = t);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInput("Notas adicionales", _notasController, maxLines: 3),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "Recordatorio automático",
                  style: TextStyle(fontFamily: 'Nunito'),
                ),
                secondary: const Icon(
                  LucideIcons.bell,
                  color: AppColors.secondary,
                ),
                value: _notificacionActiva,
                onChanged: (v) => setState(() => _notificacionActiva = v),
                activeThumbColor: AppColors.secondary,
              ),
              if (_notificacionActiva) ...[
                const Text(
                  "¿Cuándo recordarte?",
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: NotifTiming.values
                      .map(
                        (t) => ChoiceChip(
                          label: Text(
                            _timingLabel(t),
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 13,
                              color: _notifTiming == t
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          selected: _notifTiming == t,
                          onSelected: (_) => setState(() {
                            _notifTiming = t;
                            _customNotifDateTime = null;
                          }),
                          selectedColor: AppColors.secondary,
                          backgroundColor: AppColors.inputBackground.withAlpha(
                            100,
                          ),
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
                if (_notifTiming == NotifTiming.personalizado) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickCustomNotifDateTime,
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground.withAlpha(100),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.calendarClock,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _customNotifDateTime != null
                                ? DateFormat(
                                    'dd/MM/yyyy · HH:mm',
                                  ).format(_customNotifDateTime!)
                                : 'Seleccionar fecha y hora',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              color: _customNotifDateTime != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Agendar Cita",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    String hint,
    TextEditingController controller, {
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.inputBackground.withAlpha(100),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (v) =>
          isRequired && (v == null || v.isEmpty) ? "Campo obligatorio" : null,
    );
  }

  Widget _buildSelector(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.inputBackground.withAlpha(100),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.secondary),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditPerfilSheet extends StatefulWidget {
  final Mascota mascota;
  final ModuloVetConfig? config;
  final VoidCallback onSaved;

  const _EditPerfilSheet({
    required this.mascota,
    this.config,
    required this.onSaved,
  });

  @override
  State<_EditPerfilSheet> createState() => _EditPerfilSheetState();
}

class _EditPerfilSheetState extends State<_EditPerfilSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pesoController;
  late TextEditingController _alergiasController;
  late TextEditingController _urgenciasController;
  late TextEditingController _seguroController;
  late List<_VetEntry> _vetEntries;

  @override
  void initState() {
    super.initState();
    _pesoController = TextEditingController(
      text: widget.mascota.peso.toString(),
    );
    _alergiasController = TextEditingController(
      text: widget.config?.alergias.join(', ') ?? '',
    );
    _urgenciasController = TextEditingController(
      text: widget.config?.telUrgencias ?? '',
    );
    _seguroController = TextEditingController(
      text: widget.config?.seguroMedico ?? '',
    );

    _vetEntries = (widget.config?.veterinarios ?? [])
        .map(
          (v) => _VetEntry(
            nombre: v['nombre'] ?? '',
            tel: v['telefono'] ?? '',
            colegiado: v['numColegiado'] ?? '',
          ),
        )
        .toList();
    if (_vetEntries.isEmpty) _vetEntries.add(_VetEntry());
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _alergiasController.dispose();
    _urgenciasController.dispose();
    _seguroController.dispose();
    for (final e in _vetEntries) {
      e.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    final double? nuevoPeso = double.tryParse(_pesoController.text);

    if (nuevoPeso != null && nuevoPeso != widget.mascota.peso) {
      final updatedMascota = Mascota(
        mascotaID: widget.mascota.mascotaID,
        nombre: widget.mascota.nombre,
        especie: widget.mascota.especie,
        raza: widget.mascota.raza,
        chip: widget.mascota.chip,
        peso: nuevoPeso,
        fechaNacimiento: widget.mascota.fechaNacimiento,
        genero: widget.mascota.genero,
        esterilizado: widget.mascota.esterilizado,
        observaciones: widget.mascota.observaciones,
        fotoUrl: widget.mascota.fotoUrl,
        familiaID: widget.mascota.familiaID,
        modulos: widget.mascota.modulos,
      );
      await FirestoreService().actualizarMascota(updatedMascota);
    }

    final vetes = _vetEntries
        .where((e) => e.nombreCtrl.text.trim().isNotEmpty)
        .map(
          (e) => {
            'nombre': e.nombreCtrl.text.trim(),
            'telefono': e.telCtrl.text.trim(),
            'numColegiado': e.colegiadoCtrl.text.trim(),
          },
        )
        .toList();

    final config = ModuloVetConfig(
      alergias: _alergiasController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      veterinarios: vetes,
      telUrgencias: _urgenciasController.text.trim(),
      seguroMedico: _seguroController.text.trim(),
    );

    await FirestoreService().saveModuloVetConfig(
      widget.mascota.familiaID,
      widget.mascota.mascotaID,
      config,
    );
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Editar Perfil Médico",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildInput(
                      "Peso (kg)",
                      _pesoController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInput("Seguro Médico", _seguroController),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInput("Alergias (separadas por coma)", _alergiasController),
              const SizedBox(height: 20),

              // --- Veterinarios ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Veterinarios / Clínicas",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _vetEntries.add(_VetEntry())),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      "Añadir",
                      style: TextStyle(fontFamily: 'Nunito'),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (int i = 0; i < _vetEntries.length; i++) ...[
                _buildVetEntryForm(i),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 8),
              _buildInput(
                "TELÉFONO URGENCIAS 24H",
                _urgenciasController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Guardar Cambios",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVetEntryForm(int index) {
    final e = _vetEntries[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground.withAlpha(60),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withAlpha(40)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInput("Clínica / Veterinario *", e.nombreCtrl),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.redAccent,
                  size: 20,
                ),
                onPressed: _vetEntries.length > 1
                    ? () => setState(() => _vetEntries.removeAt(index))
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInput(
                  "Teléfono",
                  e.telCtrl,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: _buildInput("Nº Colegiado", e.colegiadoCtrl)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
    );
  }
}

class CitaDetailSheet extends StatelessWidget {
  final CitaVeterinaria cita;
  final Mascota mascota;

  const CitaDetailSheet({required this.cita, required this.mascota});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightSecondary.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.stethoscope,
                  color: AppColors.secondary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cita.motivo,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat(
                        'EEEE, d MMMM yyyy · HH:mm',
                        'es',
                      ).format(cita.fecha),
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (cita.veterinario != null)
            _buildDetailRow(
              LucideIcons.mapPin,
              "Veterinario / Clínica",
              cita.veterinario!,
            ),
          if (cita.notas != null)
            _buildDetailRow(LucideIcons.fileText, "Notas", cita.notas!),
          _buildDetailRow(
            LucideIcons.bell,
            "Recordatorio",
            cita.notificacionActiva ? "Activado" : "Desactivado",
            color: cita.notificacionActiva ? Colors.green : Colors.grey,
          ),
          _buildDetailRow(
            LucideIcons.checkCircle,
            "Estado",
            cita.completada ? "Completada" : "Pendiente",
            color: cita.completada ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Cerrar",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
