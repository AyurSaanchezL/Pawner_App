import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/horario_model.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/services/firestore_service.dart';
import 'package:pawner_app/services/notification_service.dart';

class HorariosScreen extends StatefulWidget {
  final Mascota mascota;

  const HorariosScreen({super.key, required this.mascota});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  final FirestoreService _fs = FirestoreService();
  final NotificationService _notifications = NotificationService();
  int _modoSeleccionado = 0; // 0=Fijo, 1=Intervalos, 2=Repeticiones

  // Modo Fijo
  TimeOfDay? _horaDesayuno;
  TimeOfDay? _horaAlmuerzo;
  TimeOfDay? _horaCena;

  // Modo Intervalos
  int _intervaloHoras = 4;

  // Modo Repeticiones
  int _numComidas = 3;
  TimeOfDay _horaInicio = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaFin = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _horaDesayuno = const TimeOfDay(hour: 8, minute: 0);
    _horaAlmuerzo = const TimeOfDay(hour: 14, minute: 0);
    _horaCena = const TimeOfDay(hour: 20, minute: 0);
  }

  int _generarIdNotificacion() {
    return DateTime.now().millisecondsSinceEpoch % 100000;
  }

  Future<void> _crearHorarioFijo() async {
    final horarios = [
      if (_horaDesayuno != null) _buildHorario('Desayuno', _horaDesayuno!),
      if (_horaAlmuerzo != null) _buildHorario('Almuerzo', _horaAlmuerzo!),
      if (_horaCena != null) _buildHorario('Cena', _horaCena!),
    ];
    await _guardarHorarios(horarios);
  }

  Future<void> _crearHorarioIntervalos() async {
    final horarios = <HorarioComida>[];
    final ahora = DateTime.now();
    for (int i = 0; i < 24; i += _intervaloHoras) {
      final hora = TimeOfDay(hour: (ahora.hour + i) % 24, minute: 0);
      final label = 'Cada ${_intervaloHoras}h';
      horarios.add(_buildHorario(label, hora));
    }
    await _guardarHorarios(horarios);
  }

  Future<void> _crearHorarioRepeticiones() async {
    final startMin = _horaInicio.hour * 60 + _horaInicio.minute;
    final endMin = _horaFin.hour * 60 + _horaFin.minute;
    final totalMin = endMin - startMin;
    final step = totalMin ~/ (_numComidas - 1);

    final horarios = <HorarioComida>[];
    for (int i = 0; i < _numComidas; i++) {
      final min = startMin + (step * i);
      final hora = TimeOfDay(hour: min ~/ 60, minute: min % 60);
      horarios.add(_buildHorario('Comida ${i + 1}', hora));
    }
    await _guardarHorarios(horarios);
  }

  HorarioComida _buildHorario(String label, TimeOfDay hora) {
    final idNotif = _generarIdNotificacion();
    final horaStr = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
    return HorarioComida(
      id: '${label}_${horaStr}_${DateTime.now().millisecondsSinceEpoch}',
      hora: horaStr,
      idNotificacion: idNotif,
      activo: true,
    );
  }

  Future<void> _guardarHorarios(List<HorarioComida> horarios) async {
    for (final h in horarios) {
      await _fs.saveHorario(
        widget.mascota.familiaID,
        widget.mascota.mascotaID,
        h,
      );
      final parts = h.hora.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      await _notifications.scheduleFixedTimeNotification(
        hour: hour,
        minute: minute,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Horarios guardados y notificaciones activadas"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _toggleHorario(HorarioComida h, bool activo) async {
    await _fs.toggleHorarioActivo(
      widget.mascota.familiaID,
      widget.mascota.mascotaID,
      h.id,
      activo,
    );
    if (!activo) {
      await _notifications.cancel(h.idNotificacion);
    } else {
      final parts = h.hora.split(':');
      await _notifications.scheduleFixedTimeNotification(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
  }

  Future<void> _eliminarHorario(HorarioComida h) async {
    await _notifications.cancel(h.idNotificacion);
    await _fs.deleteHorario(
      widget.mascota.familiaID,
      widget.mascota.mascotaID,
      h.id,
    );
  }

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) async {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.secondary),
          ),
          child: child!,
        );
      },
    );
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
        title: const Text(
          "Horarios de Comida",
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Selector de modo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text("Fijo")),
                ButtonSegment(value: 1, label: Text("Intervalos")),
                ButtonSegment(value: 2, label: Text("Repeticiones")),
              ],
              selected: {_modoSeleccionado},
              onSelectionChanged: (set) => setState(() => _modoSeleccionado = set.first),
            ),
          ),
          // Formulario según modo
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  if (_modoSeleccionado == 0) _buildModoFijo(),
                  if (_modoSeleccionado == 1) _buildModoIntervalos(),
                  if (_modoSeleccionado == 2) _buildModoRepeticiones(),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_modoSeleccionado == 0) _crearHorarioFijo();
                        if (_modoSeleccionado == 1) _crearHorarioIntervalos();
                        if (_modoSeleccionado == 2) _crearHorarioRepeticiones();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.complementary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        "Guardar Horarios",
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
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    "Horarios activos",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<HorarioComida>>(
                    stream: _fs.streamHorarios(
                      widget.mascota.familiaID,
                      widget.mascota.mascotaID,
                    ),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final horarios = snapshot.data!;
                      if (horarios.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "No hay horarios configurados.",
                            style: TextStyle(color: Colors.grey, fontFamily: 'Nunito'),
                          ),
                        );
                      }
                      return Column(
                        children: horarios.map((h) => _buildHorarioTile(h)).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModoFijo() {
    return Column(
      children: [
        _buildTimePickerTile("Desayuno", _horaDesayuno, (t) => setState(() => _horaDesayuno = t)),
        _buildTimePickerTile("Almuerzo", _horaAlmuerzo, (t) => setState(() => _horaAlmuerzo = t)),
        _buildTimePickerTile("Cena", _horaCena, (t) => setState(() => _horaCena = t)),
      ],
    );
  }

  Widget _buildModoIntervalos() {
    return Column(
      children: [
        const Text(
          "Repetir cada X horas",
          style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.minus, color: AppColors.secondary),
              onPressed: () => setState(() => _intervaloHoras = max(1, _intervaloHoras - 1)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lightSecondary.withAlpha(51),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                "$_intervaloHoras h",
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.plus, color: AppColors.secondary),
              onPressed: () => setState(() => _intervaloHoras = min(24, _intervaloHoras + 1)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModoRepeticiones() {
    return Column(
      children: [
        const Text(
          "Nº de comidas",
          style: TextStyle(fontFamily: 'Nunito', fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.minus, color: AppColors.secondary),
              onPressed: () => setState(() => _numComidas = max(2, _numComidas - 1)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.lightSecondary.withAlpha(51),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                "$_numComidas",
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.plus, color: AppColors.secondary),
              onPressed: () => setState(() => _numComidas = min(10, _numComidas + 1)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildTimePickerTile("Hora inicio", _horaInicio, (t) => setState(() => _horaInicio = t!)),
        _buildTimePickerTile("Hora fin", _horaFin, (t) => setState(() => _horaFin = t!)),
      ],
    );
  }

  Widget _buildTimePickerTile(String label, TimeOfDay? value, Function(TimeOfDay?) onPicked) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.lightSecondary.withAlpha(51),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.clock, color: AppColors.secondary, size: 20),
        ),
        title: Text(label, style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
        subtitle: Text(
          value != null
              ? "${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}"
              : "Sin definir",
          style: const TextStyle(fontFamily: 'Nunito', color: Colors.grey),
        ),
        trailing: const Icon(LucideIcons.chevronRight, color: Colors.grey),
        onTap: () async {
          final picked = await _pickTime(context, value ?? const TimeOfDay(hour: 12, minute: 0));
          if (picked != null) onPicked(picked);
        },
      ),
    );
  }

  Widget _buildHorarioTile(HorarioComida h) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: h.activo ? Colors.green.withAlpha(26) : Colors.red.withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: Icon(
            LucideIcons.bell,
            color: h.activo ? Colors.green : Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          h.hora,
          style: const TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          h.activo ? "Activo" : "Desactivado",
          style: TextStyle(
            fontFamily: 'Nunito',
            color: h.activo ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: h.activo,
              onChanged: (v) => _toggleHorario(h, v),
              activeColor: AppColors.secondary,
            ),
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20),
              onPressed: () => _eliminarHorario(h),
            ),
          ],
        ),
      ),
    );
  }
}
