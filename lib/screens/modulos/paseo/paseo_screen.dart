import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/components/number_picker.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/modulo_paseos/model_paseo.dart';
import 'package:pawner_app/core/model/modulo_paseos/modulo_paseo_config.dart';
import 'package:pawner_app/screens/modulos/paseo/config_objetivo_paseos.dart';
import 'package:pawner_app/services/cloudinary_service.dart';
import 'package:pawner_app/services/firestore_service.dart';
import 'package:pawner_app/services/notification_service.dart';
import 'package:pawner_app/services/push_notification_service.dart';

class PaseoScreen extends StatefulWidget {
  final Mascota m;
  const PaseoScreen({super.key, required this.m});

  @override
  State<PaseoScreen> createState() => _PaseoScreenState();
}

class _PaseoScreenState extends State<PaseoScreen> {
  List<Paseo> paseos = [];
  String titulo = "";

  @override
  void initState() {
    super.initState();
    _syncPaseoNotifications();
  }

  Future<void> _syncPaseoNotifications() async {
    final config = await FirestoreService()
        .getPaseoConfig(widget.m.familiaID, widget.m.mascotaID)
        .first;
    if (config == null) return;

    final count = await FirestoreService().countPaseosToday(
      widget.m.familiaID,
      widget.m.mascotaID,
    );

    if (!mounted) return;

    if (count >= config.numPaseosObjetivo) {
      await NotificationService().cancelPaseoReminders();
      return;
    }

    // No reprogramar si ya hay recordatorios pendientes: evita resetear el intervalo
    final hasPending = await NotificationService().hasPendingPaseoReminders();
    if (hasPending) return;

    await NotificationService().schedulePaseoReminders(
      objetivo: config.numPaseosObjetivo,
      completadosHoy: count,
      intervaloHoras: config.intervaloRecordatoriosHoras,
      mascotaNombre: widget.m.nombre,
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Primer Stream: configuración (objetivo de paseos)
    return StreamBuilder<PaseoConfig?>(
      stream: FirestoreService().getPaseoConfig(
        widget.m.familiaID,
        widget.m.mascotaID,
      ),
      builder: (context, configSnapshot) {
        final config = configSnapshot.data;

        // 2. Segundo Stream: lista de paseos
        return StreamBuilder<List<Paseo>>(
          stream: FirestoreService().readPaseos(
            widget.m.familiaID,
            widget.m.mascotaID,
          ),
          builder: (context, snapshot) {
            // Manejo de errores y carga
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Text("Error: ${snapshot.error}")),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _cargando();
            }

            paseos = snapshot.data ?? [];
            List<Paseo> paseosAyer = [];
            for (Paseo p in paseos) {
              if (p.fechaHora.toDate().day != DateTime.now().day) {
                paseosAyer.add(p);
              }
            }

            if (paseosAyer.isNotEmpty) {
              _deletePaseos(widget.m, paseosAyer);
              for (Paseo p in paseosAyer) {
                paseos.remove(p);
              }
            }

            final hoy = DateTime.now();
            final paseosHoy = paseos.where((p) {
              final fecha = p.fechaHora.toDate();
              return fecha.year == hoy.year &&
                  fecha.month == hoy.month &&
                  fecha.day == hoy.day;
            }).length;

            String tituloDinamico = "Paseos de ${widget.m.nombre}";
            if (config != null) {
              tituloDinamico += " ($paseosHoy / ${config.numPaseosObjetivo})";
            }

            return Scaffold(
              backgroundColor: AppColors.homeScreenBackground,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(
                    LucideIcons.chevronLeft,
                    color: Colors.black,
                    size: 30,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  tituloDinamico,
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.clock,
                      color: AppColors.secondary,
                    ),
                    onPressed: () => _configurarObjetivo(),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddPaseo(mascota: widget.m),
                  );
                },
                backgroundColor: AppColors.accent,
                child: const Icon(LucideIcons.plus, color: AppColors.cardWhite),
              ),
              body: paseos.isEmpty
                  ? Center(
                      child: Text(
                        "Hoy ${widget.m.nombre} no ha dado ningún paseo...",
                      ),
                    )
                  : _buildPage(), // Tu función de siempre
            );
          },
        );
      },
    );
  }

  Widget _buildPage() {
    paseos.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: paseos.length,
      itemBuilder: (context, index) {
        final paseo = paseos[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
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
              if (paseo.urlFoto != null && paseo.urlFoto!.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    paseo.urlFoto!,
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      color: Colors.grey,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${paseo.fechaHora.toDate().hour}:${paseo.fechaHora.toDate().minute.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(51),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _formatearTiempo(paseo.tiempoMinutos),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (paseo.observaciones != null)
                      Text(
                        paseo.observaciones!,
                        style: const TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _editarPaseo(paseo),
                          icon: const Icon(LucideIcons.edit2, size: 18),
                          label: const Text('Editar'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () => _confirmDelete(paseo),
                          icon: const Icon(LucideIcons.trash2, size: 18),
                          label: const Text('Eliminar'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deletePaseos(Mascota m, List<Paseo> paseos) async {
    try {
      for (Paseo p in paseos) {
        await FirestoreService().deletePaseo(m.familiaID, m.mascotaID, p);
      }
    } catch (e) {
      log("No fue posible eliminar todos los paseos de ayer");
    }
  }

  String _formatearTiempo(int totalMinutos) {
    if (totalMinutos < 60) return "$totalMinutos min";
    int h = totalMinutos ~/ 60;
    int m = totalMinutos % 60;
    return m == 0 ? "${h}h" : "${h}h ${m}min";
  }

  Future<void> _editarPaseo(Paseo paseo) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPaseo(mascota: widget.m, paseo: paseo),
    );
  }

  Future<void> _confirmDelete(Paseo paseo) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar paseo'),
        content: const Text('¿Seguro que quieres eliminar este paseo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await FirestoreService().deletePaseo(
          widget.m.familiaID,
          widget.m.mascotaID,
          paseo,
        );
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(content: Text('Paseo eliminado')),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('No se pudo eliminar: $e')),
          );
        }
      }
    }
  }

  Widget _cargando() {
    return const Center(child: CircularProgressIndicator());
  }

  Future<void> _configurarObjetivo() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConfigObjetivoPaseos(
        familiaID: widget.m.familiaID,
        mascotaID: widget.m.mascotaID,
        mascotaNombre: widget.m.nombre,
      ),
    );
  }
}

// --- CLASE ADD PASEO ---
class AddPaseo extends StatefulWidget {
  final Mascota mascota;
  final Paseo? paseo;
  const AddPaseo({super.key, required this.mascota, this.paseo});

  @override
  State<AddPaseo> createState() => _AddPaseoState();
}

class _AddPaseoState extends State<AddPaseo> {
  TextEditingController observacionesController = TextEditingController();
  int horas = 0;
  int minutos = 30;
  File? _imageFile;
  bool _isSaving = false;

  bool get isEditing => widget.paseo != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      observacionesController.text = widget.paseo?.observaciones ?? '';
      final total = widget.paseo?.tiempoMinutos ?? 0;
      horas = total ~/ 60;
      minutos = total % 60;
    }
  }

  Future<void> _guardarPaseo() async {
    final tiempoTotal = (horas * 60) + minutos;
    final navigator = Navigator.of(context);
    setState(() => _isSaving = true);

    try {
      String? imageUrl;
      if (_imageFile != null) {
        imageUrl = await CloudinaryService().uploadImage(_imageFile!);
      }

      final newPaseo = Paseo(
        paseoID: widget.paseo?.paseoID ?? '',
        observaciones: observacionesController.text.trim(),
        tiempoMinutos: tiempoTotal,
        fechaHora: widget.paseo?.fechaHora ?? Timestamp.now(),
        urlFoto: imageUrl ?? widget.paseo?.urlFoto,
      );

      if (isEditing) {
        await FirestoreService().updatePaseo(
          newPaseo,
          widget.mascota.familiaID,
          widget.mascota.mascotaID,
        );
      } else {
        await FirestoreService().addPaseo(
          newPaseo,
          widget.mascota.familiaID,
          widget.mascota.mascotaID,
        );
        // await NotificationService().;
        await FCMService().enviarNotificacionFamiliar(
          topic: widget.mascota.familiaID,
          title: "Nuevo paseo",
          body: '${widget.mascota.nombre} ha dado un paseo!',
        );
      }

      await _refreshPaseoReminders();

      if (!mounted) return;
      navigator.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _refreshPaseoReminders() async {
    final config = await FirestoreService()
        .getPaseoConfig(widget.mascota.familiaID, widget.mascota.mascotaID)
        .first;
    if (config == null) return;

    final count = await FirestoreService().countPaseosToday(
      widget.mascota.familiaID,
      widget.mascota.mascotaID,
    );

    if (count < config.numPaseosObjetivo) {
      await NotificationService().schedulePaseoReminders(
        objetivo: config.numPaseosObjetivo,
        completadosHoy: count,
        intervaloHoras: config.intervaloRecordatoriosHoras,
        mascotaNombre: widget.mascota.nombre,
      );
    } else {
      await NotificationService().cancelPaseoReminders();
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) setState(() => _imageFile = File(pickedFile.path));
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
        child: Column(
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
            Text(
              isEditing ? 'Editar Paseo' : 'Nuevo Paseo',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: observacionesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Observaciones...",
                filled: true,
                fillColor: AppColors.inputBackground.withAlpha(180),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomNumberPicker(
                  context: context,
                  label: "Horas",
                  backgroundColor: Colors.transparent,
                  val: horas,
                  min: 0,
                  max: 23,
                  onChanged: (val) => setState(() => horas = val),
                ),
                const Text(
                  ":",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                CustomNumberPicker(
                  context: context,
                  label: "Minutos",
                  backgroundColor: Colors.transparent,
                  val: minutos,
                  min: 0,
                  max: 59,
                  onChanged: (val) => setState(() => minutos = val),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.inputBackground.withAlpha(180),
                  borderRadius: BorderRadius.circular(20),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : (isEditing &&
                            widget.paseo?.urlFoto != null &&
                            widget.paseo!.urlFoto!.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(widget.paseo!.urlFoto!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child:
                    (_imageFile == null &&
                        !(isEditing &&
                            widget.paseo?.urlFoto != null &&
                            widget.paseo!.urlFoto!.isNotEmpty))
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.camera,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Añadir foto',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                              fontFamily: 'Nunito',
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _guardarPaseo,
                style: ElevatedButton.styleFrom(
                  elevation: 3,
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 30,
                        width: 30,
                        child: CircularProgressIndicator(),
                      )
                    : const Text(
                        "GUARDAR PASEO",
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
