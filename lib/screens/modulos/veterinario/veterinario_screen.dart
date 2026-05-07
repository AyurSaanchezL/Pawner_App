import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/cita_veterinaria.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/services/firestore_service.dart';
import 'package:pawner_app/services/notification_service.dart';

class VeterinarioScreen extends StatefulWidget {
  final Mascota mascota;

  const VeterinarioScreen({super.key, required this.mascota});

  @override
  State<VeterinarioScreen> createState() => _VeterinarioScreenState();
}

class _VeterinarioScreenState extends State<VeterinarioScreen> {
  final FirestoreService _fs = FirestoreService();
  final NotificationService _notifications = NotificationService();

  final _formKey = GlobalKey<FormState>();
  final _motivoController = TextEditingController();
  final _veterinarioController = TextEditingController();
  final _notasController = TextEditingController();
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();
  bool _notificacionActiva = true;

  int _generarIdNotificacion() {
    return DateTime.now().millisecondsSinceEpoch % 100000;
  }

  Future<void> _guardarCita() async {
    if (!_formKey.currentState!.validate()) return;

    final fechaHora = DateTime(
      _fecha.year,
      _fecha.month,
      _fecha.day,
      _hora.hour,
      _hora.minute,
    );

    final idNotif = _notificacionActiva ? _generarIdNotificacion() : null;

    final cita = CitaVeterinaria(
      id: '',
      fecha: fechaHora,
      motivo: _motivoController.text.trim(),
      veterinario: _veterinarioController.text.trim().isEmpty
          ? null
          : _veterinarioController.text.trim(),
      notas: _notasController.text.trim().isEmpty
          ? null
          : _notasController.text.trim(),
      notificacionActiva: _notificacionActiva,
      idNotificacion: idNotif,
    );

    await _fs.addCitaVeterinaria(
      widget.mascota.familiaID,
      widget.mascota.mascotaID,
      cita,
    );

    if (_notificacionActiva && idNotif != null) {
      final minutesDiff = fechaHora.difference(DateTime.now()).inMinutes;
      if (minutesDiff > 0) {
        await _notifications.scheduleOneTimeNotification(minutes: minutesDiff);
      }
    }

    if (mounted) {
      _motivoController.clear();
      _veterinarioController.clear();
      _notasController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cita guardada correctamente"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _eliminarCita(CitaVeterinaria cita) async {
    if (cita.idNotificacion != null) {
      await _notifications.cancel(cita.idNotificacion!);
    }
    await _fs.deleteCitaVeterinaria(
      widget.mascota.familiaID,
      widget.mascota.mascotaID,
      cita.id,
    );
  }

  Future<void> _toggleNotificacion(CitaVeterinaria cita, bool activa) async {
    cita.notificacionActiva = activa;
    if (!activa && cita.idNotificacion != null) {
      await _notifications.cancel(cita.idNotificacion!);
    } else if (activa) {
      cita.idNotificacion = _generarIdNotificacion();
      final minutesDiff = cita.fecha.difference(DateTime.now()).inMinutes;
      if (minutesDiff > 0) {
        await _notifications.scheduleOneTimeNotification(minutes: minutesDiff);
      }
    }
    await _fs.updateCitaVeterinaria(
      widget.mascota.familiaID,
      widget.mascota.mascotaID,
      cita,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.secondary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.secondary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _hora = picked);
  }

  String _formatFecha(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeScreenBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Veterinario · ${widget.mascota.nombre}",
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nueva cita",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(_motivoController, "Motivo *", isRequired: true),
                        const SizedBox(height: 16),
                        _buildTextField(_veterinarioController, "Veterinario / Clínica", isRequired: false),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDateTile(
                                "Fecha",
                                _formatFecha(_fecha),
                                () => _selectDate(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateTile(
                                "Hora",
                                "${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}",
                                () => _selectTime(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(_notasController, "Notas adicionales", isRequired: false, maxLines: 3),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text(
                            "Notificación de recordatorio",
                            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
                          ),
                          value: _notificacionActiva,
                          onChanged: (v) => setState(() => _notificacionActiva = v),
                          activeColor: AppColors.secondary,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _guardarCita,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              "Guardar Cita",
                              style: TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    "Próximas citas",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          StreamBuilder<List<CitaVeterinaria>>(
            stream: _fs.streamCitasVeterinarias(
              widget.mascota.familiaID,
              widget.mascota.mascotaID,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final citas = snapshot.data!;
              if (citas.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(
                      child: Text(
                        "No hay citas registradas.",
                        style: TextStyle(color: Colors.grey, fontFamily: 'Nunito'),
                      ),
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildCitaCard(citas[index]),
                    childCount: citas.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint,
      {bool isRequired = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFE1D5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      validator: (v) {
        if (isRequired && (v == null || v.isEmpty)) return "Campo requerido";
        return null;
      },
    );
  }

  Widget _buildDateTile(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE1D5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitaCard(CitaVeterinaria cita) {
    final bool pasada = cita.fecha.isBefore(DateTime.now());
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: pasada ? Colors.grey.shade100 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: pasada ? Colors.grey.withAlpha(26) : AppColors.lightSecondary.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.stethoscope,
                    color: pasada ? Colors.grey : AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cita.motivo,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: pasada ? Colors.grey : Colors.black,
                        ),
                      ),
                      Text(
                        "${_formatFecha(cita.fecha)} · ${cita.fecha.hour.toString().padLeft(2, '0')}:${cita.fecha.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: pasada ? Colors.grey : AppColors.secondary,
                        ),
                      ),
                      if (cita.veterinario != null && cita.veterinario!.isNotEmpty)
                        Text(
                          cita.veterinario!,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                  onPressed: () => _eliminarCita(cita),
                ),
              ],
            ),
            if (cita.notas != null && cita.notas!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.homeScreenBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cita.notas!,
                  style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, color: Colors.black54),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  cita.notificacionActiva ? "Notificación activa" : "Sin notificación",
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    color: cita.notificacionActiva ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: cita.notificacionActiva,
                  onChanged: (v) => _toggleNotificacion(cita, v),
                  activeColor: AppColors.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
