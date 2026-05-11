import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/modulo_comida/horario_model.dart';
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

  TimeOfDay _horaDesayuno = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _horaAlmuerzo = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _horaCena = const TimeOfDay(hour: 20, minute: 0);

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  HorarioComida _buildHorario(TimeOfDay hora) {
    final horaStr = _formatTime(hora);
    final idNotif = DateTime.now().millisecondsSinceEpoch % 100000;
    return HorarioComida(
      id: '${horaStr}_${DateTime.now().millisecondsSinceEpoch}',
      hora: horaStr,
      idNotificacion: idNotif,
      activo: true,
    );
  }

  Future<void> _guardarHorarios() async {
    final horarios = [
      _buildHorario(_horaDesayuno),
      _buildHorario(_horaAlmuerzo),
      _buildHorario(_horaCena),
    ];
    for (final h in horarios) {
      await _fs.saveHorario(widget.mascota.familiaID, widget.mascota.mascotaID, h);
      final parts = h.hora.split(':');
      await _notifications
          .scheduleFixedTimeNotification(
            id: h.idNotificacion,
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          )
          .catchError((_) {});
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Horarios guardados',
            style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
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
      await _notifications
          .scheduleFixedTimeNotification(
            id: h.idNotificacion,
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          )
          .catchError((_) {});
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

  Future<void> _pickTime(TimeOfDay current, void Function(TimeOfDay) onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.secondary),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeScreenBackground,
      appBar: _buildAppBar(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildFormCard()),
          SliverToBoxAdapter(child: _buildSectionHeader()),
          _buildHorariosList(),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(LucideIcons.chevronLeft, color: Colors.black, size: 30),
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
            child: const Icon(LucideIcons.clock, size: 16, color: AppColors.secondary),
          ),
          const SizedBox(width: 10),
          Text(
            'Horarios · ${widget.mascota.nombre}',
            style: const TextStyle(
              fontFamily: 'Nunito',
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.clock, size: 15, color: AppColors.secondary),
                const SizedBox(width: 6),
                const Text(
                  'Nuevo horario',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimeRow(
              label: 'Desayuno',
              value: _horaDesayuno,
              onTap: () => _pickTime(_horaDesayuno, (t) => setState(() => _horaDesayuno = t)),
            ),
            const SizedBox(height: 10),
            _buildTimeRow(
              label: 'Almuerzo',
              value: _horaAlmuerzo,
              onTap: () => _pickTime(_horaAlmuerzo, (t) => setState(() => _horaAlmuerzo = t)),
            ),
            const SizedBox(height: 10),
            _buildTimeRow(
              label: 'Cena',
              value: _horaCena,
              onTap: () => _pickTime(_horaCena, (t) => setState(() => _horaCena = t)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardarHorarios,
                icon: const Icon(LucideIcons.bell, size: 16, color: Colors.white),
                label: const Text(
                  'Añadir horarios',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow({
    required String label,
    required TimeOfDay value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.homeScreenBackground,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.clock, size: 16, color: AppColors.secondary),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Text(
              _formatTime(value),
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Row(
        children: [
          const Icon(LucideIcons.list, size: 16, color: AppColors.secondary),
          const SizedBox(width: 6),
          const Text(
            'Horarios activos',
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorariosList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: StreamBuilder<List<HorarioComida>>(
        stream: _fs.streamHorarios(widget.mascota.familiaID, widget.mascota.mascotaID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (snapshot.hasError) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error al cargar los horarios',
                  style: TextStyle(fontFamily: 'Nunito', color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final horarios = snapshot.data ?? [];
          if (horarios.isEmpty) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                child: Column(
                  children: [
                    Icon(LucideIcons.bell, size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text(
                      'Sin horarios configurados',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _buildHorarioTile(horarios[i]),
              childCount: horarios.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorarioTile(HorarioComida h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: h.activo
                    ? AppColors.lightSecondary.withAlpha(60)
                    : Colors.grey.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.bell,
                size: 20,
                color: h.activo ? AppColors.secondary : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              h.hora,
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: h.activo ? Colors.black87 : Colors.grey.shade400,
              ),
            ),
            const Spacer(),
            Switch(
              value: h.activo,
              onChanged: (v) => _toggleHorario(h, v),
              activeThumbColor: AppColors.secondary,
              activeTrackColor: AppColors.lightSecondary,
            ),
            IconButton(
              icon: Icon(LucideIcons.trash2, size: 18, color: Colors.grey.shade400),
              onPressed: () => _eliminarHorario(h),
            ),
          ],
        ),
      ),
    );
  }
}
