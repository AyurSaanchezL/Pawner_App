import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/modulo_higiene/modulo_higiene_config.dart';
import 'package:pawner_app/core/model/modulo_higiene/registro_bano.dart';
import 'package:pawner_app/core/components/notification_permission_dialog.dart';
import 'package:pawner_app/services/firestore_service.dart';
import 'package:pawner_app/services/notification_service.dart';
import 'higiene_contexto_sheet.dart';
import 'add_bano_sheet.dart';
import 'edit_bano_sheet.dart';

DateTime _calcularProximoAviso(
  DateTime base,
  int frecuenciaDias,
  TimeOfDay hora,
) {
  final d = base.add(Duration(days: frecuenciaDias));
  final candidato = DateTime(d.year, d.month, d.day, hora.hour, hora.minute);
  if (candidato.isAfter(DateTime.now())) return candidato;
  final d2 = DateTime.now().add(Duration(days: frecuenciaDias));
  return DateTime(d2.year, d2.month, d2.day, hora.hour, hora.minute);
}

InputDecoration _pawnerInput({
  String? label,
  String? hint,
  Widget? suffix,
  Widget? prefix,
}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
      prefixIcon: prefix,
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
      ),
      labelStyle: const TextStyle(fontFamily: 'Nunito'),
      hintStyle: const TextStyle(fontFamily: 'Nunito', color: Colors.grey),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

BoxDecoration _cardDecoration() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(13),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );

ButtonStyle _primaryButtonStyle() => ElevatedButton.styleFrom(
      backgroundColor: AppColors.secondary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      padding: const EdgeInsets.symmetric(vertical: 14),
      textStyle: const TextStyle(
        fontFamily: 'Nunito',
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    );

class HigieneScreen extends StatefulWidget {
  final Mascota mascota;
  final String familiaID;

  const HigieneScreen({
    required this.mascota,
    required this.familiaID,
    super.key,
  });

  @override
  State<HigieneScreen> createState() => _HigieneScreenState();
}

class _HigieneScreenState extends State<HigieneScreen> {
  final FirestoreService _fs = FirestoreService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationPermissionDialog.checkAndShow(
        context,
        feature: 'los recordatorios de baño de tus mascotas',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeScreenBackground,
      appBar: AppBar(
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
              child: const Icon(
                LucideIcons.sparkles,
                size: 16,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Higiene · ${widget.mascota.nombre}',
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<ModuloHigieneConfig?>(
        stream: _fs.streamModuloHigieneConfig(
          widget.familiaID,
          widget.mascota.mascotaID,
        ),
        builder: (context, configSnap) {
          if (configSnap.connectionState == ConnectionState.waiting &&
              !configSnap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            );
          }
          final config = configSnap.data;

          return StreamBuilder<List<RegistroBano>>(
            stream: _fs.streamBanos(
              widget.familiaID,
              widget.mascota.mascotaID,
            ),
            builder: (context, banosSnap) {
              final banos = banosSnap.data ?? [];

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FrecuenciaCard(
                      mascota: widget.mascota,
                      familiaID: widget.familiaID,
                      config: config,
                      fs: _fs,
                    ),
                    const SizedBox(height: 20),
                    _ProcesoHigieneBloque(
                      mascota: widget.mascota,
                      familiaID: widget.familiaID,
                      config: config,
                      fs: _fs,
                    ),
                    const SizedBox(height: 20),
                    _HistorialBanosBloque(
                      mascota: widget.mascota,
                      familiaID: widget.familiaID,
                      config: config,
                      banos: banos,
                      focusedDay: _focusedDay,
                      selectedDay: _selectedDay,
                      onDayChanged: (focused, selected) => setState(() {
                        _focusedDay = focused;
                        _selectedDay = selected;
                      }),
                      fs: _fs,
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<ModuloHigieneConfig?>(
        stream: _fs.streamModuloHigieneConfig(
          widget.familiaID,
          widget.mascota.mascotaID,
        ),
        builder: (context, snap) {
          if (snap.data?.configurado != true) return const SizedBox.shrink();
          return FloatingActionButton(
            backgroundColor: AppColors.homeScreenOrange,
            foregroundColor: Colors.black87,
            elevation: 4,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                backgroundColor: Colors.white,
                builder: (_) => AddBanoSheet(
                  familiaID: widget.familiaID,
                  mascotaID: widget.mascota.mascotaID,
                  config: snap.data!,
                  onSaved: () {},
                ),
              );
            },
            child: const Icon(Icons.add), // sustituido en vez de LucideIcons.droplets
          );
        },
      ),
    );
  }
}

// ── Bloque 1: Frecuencia ─────────────────────────────────────────────────────

class _FrecuenciaCard extends StatefulWidget {
  final Mascota mascota;
  final String familiaID;
  final ModuloHigieneConfig? config;
  final FirestoreService fs;

  const _FrecuenciaCard({
    required this.mascota,
    required this.familiaID,
    required this.config,
    required this.fs,
  });

  @override
  State<_FrecuenciaCard> createState() => _FrecuenciaCardState();
}

class _FrecuenciaCardState extends State<_FrecuenciaCard> {
  int? _frecuenciaDias;
  bool _notificacionActiva = false;
  TimeOfDay? _horaAviso;
  bool _guardando = false;

  static const _opcionesFijas = {
    7: 'Cada semana',
    14: 'Cada 2 semanas',
    21: 'Cada 3 semanas',
    30: 'Cada mes',
  };

  Future<void> _guardar() async {
    if (_frecuenciaDias == null) return;
    setState(() => _guardando = true);
    final idNotif = DateTime.now().millisecondsSinceEpoch % 100000;
    final hora = _horaAviso ?? const TimeOfDay(hour: 9, minute: 0);
    final proximoAviso =
        _calcularProximoAviso(DateTime.now(), _frecuenciaDias!, hora);
    final newConfig = ModuloHigieneConfig(
      configurado: true,
      frecuenciaDias: _frecuenciaDias!,
      notificacionActiva: _notificacionActiva,
      idNotificacion: idNotif,
      proximoAviso: proximoAviso,
    );
    await widget.fs.saveModuloHigieneConfig(
      widget.familiaID,
      widget.mascota.mascotaID,
      newConfig,
    );
    if (_notificacionActiva) {
      NotificationService().scheduleOneTimeNotification(
        id: idNotif,
        scheduledFor: proximoAviso,
        title: '🛁 Hora del baño: ${widget.mascota.nombre}',
        body: 'Según tu rutina, hoy toca bañar a ${widget.mascota.nombre}.',
      ).catchError((_) {});
    }
    if (mounted) setState(() => _guardando = false);
  }

  void _mostrarPersonalizar() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Frecuencia personalizada',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontFamily: 'Nunito'),
          decoration: _pawnerInput(label: 'Número de días', hint: 'ej. 10'),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(fontFamily: 'Nunito')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim());
              if (n != null && n > 0) setState(() => _frecuenciaDias = n);
              Navigator.pop(context);
            },
            child: const Text('Aceptar', style: TextStyle(fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config;

    if (config == null || !config.configurado) {
      return Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.lightSecondary.withAlpha(70),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.calendarClock,
                    size: 18,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '¿Cada cuántos días bañas a ${widget.mascota.nombre}?',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value:
                  _opcionesFijas.containsKey(_frecuenciaDias)
                      ? _frecuenciaDias
                      : null,
              decoration: _pawnerInput(label: 'Frecuencia de baño'),
              style: const TextStyle(
                fontFamily: 'Nunito',
                color: Colors.black87,
                fontSize: 15,
              ),
              hint: _frecuenciaDias != null &&
                      !_opcionesFijas.containsKey(_frecuenciaDias)
                  ? Text(
                      '$_frecuenciaDias días (personalizado)',
                      style: const TextStyle(fontFamily: 'Nunito'),
                    )
                  : const Text(
                      'Seleccionar frecuencia',
                      style: TextStyle(fontFamily: 'Nunito'),
                    ),
              items: [
                ..._opcionesFijas.entries.map(
                  (e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value, style: const TextStyle(fontFamily: 'Nunito')),
                  ),
                ),
                const DropdownMenuItem<int>(
                  value: -1,
                  child: Text(
                    'Personalizar…',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
              onChanged: (v) {
                if (v == -1) {
                  _mostrarPersonalizar();
                } else if (v != null) {
                  setState(() => _frecuenciaDias = v);
                }
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text(
                'Recibir recordatorio',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 14),
              ),
              value: _notificacionActiva,
              onChanged: (v) => setState(() => _notificacionActiva = v),
              activeTrackColor: AppColors.secondary,
              contentPadding: EdgeInsets.zero,
            ),
            if (_notificacionActiva) ...[
              GestureDetector(
                onTap: () async {
                  final hora = await showTimePicker(
                    context: context,
                    initialTime:
                        _horaAviso ?? const TimeOfDay(hour: 9, minute: 0),
                  );
                  if (hora != null) setState(() => _horaAviso = hora);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 16,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Hora del recordatorio: ${_horaAviso?.format(context) ?? '09:00'}',
                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: _primaryButtonStyle(),
                onPressed: (_frecuenciaDias == null || _guardando) ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Guardar frecuencia'),
              ),
            ),
          ],
        ),
      );
    }

    // Estado configurado
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.lightSecondary.withAlpha(70),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.calendarClock,
              size: 18,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cada ${config.frecuenciaDias} días',
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                if (config.notificacionActiva && config.proximoAviso != null)
                  Row(children: [
                    const Icon(LucideIcons.bell, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      'Aviso: ${DateFormat('dd/MM/yyyy HH:mm').format(config.proximoAviso!)}',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ])
                else
                  Row(children: [
                    Icon(LucideIcons.bellOff, size: 14, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'Sin recordatorio',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ]),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondary,
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                backgroundColor: Colors.white,
                builder: (_) => _FrecuenciaEditSheet(
                  mascota: widget.mascota,
                  familiaID: widget.familiaID,
                  config: config,
                  fs: widget.fs,
                ),
              );
            },
            child: const Text('Modificar'),
          ),
        ],
      ),
    );
  }
}

class _FrecuenciaEditSheet extends StatefulWidget {
  final Mascota mascota;
  final String familiaID;
  final ModuloHigieneConfig config;
  final FirestoreService fs;

  const _FrecuenciaEditSheet({
    required this.mascota,
    required this.familiaID,
    required this.config,
    required this.fs,
  });

  @override
  State<_FrecuenciaEditSheet> createState() => _FrecuenciaEditSheetState();
}

class _FrecuenciaEditSheetState extends State<_FrecuenciaEditSheet> {
  late int? _frecuenciaDias;
  late bool _notificacionActiva;
  TimeOfDay? _horaAviso;
  bool _guardando = false;

  static const _opcionesFijas = {
    7: 'Cada semana',
    14: 'Cada 2 semanas',
    21: 'Cada 3 semanas',
    30: 'Cada mes',
  };

  @override
  void initState() {
    super.initState();
    _frecuenciaDias = widget.config.frecuenciaDias;
    _notificacionActiva = widget.config.notificacionActiva;
    if (widget.config.proximoAviso != null) {
      _horaAviso = TimeOfDay.fromDateTime(widget.config.proximoAviso!);
    }
  }

  void _mostrarPersonalizar() {
    final ctrl = TextEditingController(
      text: !_opcionesFijas.containsKey(_frecuenciaDias) ? '$_frecuenciaDias' : '',
    );
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Frecuencia personalizada',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontFamily: 'Nunito'),
          decoration: _pawnerInput(label: 'Número de días'),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(fontFamily: 'Nunito')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final n = int.tryParse(ctrl.text.trim());
              if (n != null && n > 0) setState(() => _frecuenciaDias = n);
              Navigator.pop(context);
            },
            child: const Text('Aceptar', style: TextStyle(fontFamily: 'Nunito')),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    if (_frecuenciaDias == null) return;
    setState(() => _guardando = true);

    if (widget.config.idNotificacion != null) {
      await NotificationService().cancel(widget.config.idNotificacion!);
    }

    final hora = _horaAviso ?? const TimeOfDay(hour: 9, minute: 0);
    final proximoAviso =
    _calcularProximoAviso(DateTime.now(), _frecuenciaDias!, hora);
    final updated = ModuloHigieneConfig(
      configurado: true,
      frecuenciaDias: _frecuenciaDias!,
      notificacionActiva: _notificacionActiva,
      idNotificacion: widget.config.idNotificacion,
      proximoAviso: proximoAviso,
      utensilios: widget.config.utensilios,
      instrucciones: widget.config.instrucciones,
    );
    await widget.fs.saveModuloHigieneConfig(
      widget.familiaID,
      widget.mascota.mascotaID,
      updated,
    );

    if (_notificacionActiva && widget.config.idNotificacion != null) {
      NotificationService().scheduleOneTimeNotification(
        id: widget.config.idNotificacion!,
        scheduledFor: proximoAviso,
        title: '🛁 Hora del baño: ${widget.mascota.nombre}',
        body: 'Según tu rutina, hoy toca bañar a ${widget.mascota.nombre}.',
      ).catchError((_) {});
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
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
        Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Modificar frecuencia',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value:
                      _opcionesFijas.containsKey(_frecuenciaDias)
                          ? _frecuenciaDias
                          : null,
                  decoration: _pawnerInput(label: 'Frecuencia de baño'),
                  style: const TextStyle(
                    fontFamily: 'Nunito',
                    color: Colors.black87,
                    fontSize: 15,
                  ),
                  hint: _frecuenciaDias != null &&
                          !_opcionesFijas.containsKey(_frecuenciaDias)
                      ? Text(
                          '$_frecuenciaDias días (personalizado)',
                          style: const TextStyle(fontFamily: 'Nunito'),
                        )
                      : const Text(
                          'Seleccionar frecuencia',
                          style: TextStyle(fontFamily: 'Nunito'),
                        ),
                  items: [
                    ..._opcionesFijas.entries.map(
                      (e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          e.value,
                          style: const TextStyle(fontFamily: 'Nunito'),
                        ),
                      ),
                    ),
                    const DropdownMenuItem<int>(
                      value: -1,
                      child: Text(
                        'Personalizar…',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == -1) {
                      _mostrarPersonalizar();
                    } else if (v != null) {
                      setState(() => _frecuenciaDias = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text(
                    'Recibir recordatorio',
                    style: TextStyle(fontFamily: 'Nunito', fontSize: 14),
                  ),
                  value: _notificacionActiva,
                  onChanged: (v) => setState(() => _notificacionActiva = v),
                  activeTrackColor: AppColors.secondary,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_notificacionActiva) ...[
                  GestureDetector(
                    onTap: () async {
                      final hora = await showTimePicker(
                        context: context,
                        initialTime:
                            _horaAviso ?? const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (hora != null) setState(() => _horaAviso = hora);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Hora del recordatorio: ${_horaAviso?.format(context) ?? '09:00'}',
                            style: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: _primaryButtonStyle(),
                    onPressed: (_frecuenciaDias == null || _guardando)
                        ? null
                        : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Guardar cambios'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bloque 2: Proceso de higiene ─────────────────────────────────────────────

class _ProcesoHigieneBloque extends StatefulWidget {
  final Mascota mascota;
  final String familiaID;
  final ModuloHigieneConfig? config;
  final FirestoreService fs;

  const _ProcesoHigieneBloque({
    required this.mascota,
    required this.familiaID,
    required this.config,
    required this.fs,
  });

  @override
  State<_ProcesoHigieneBloque> createState() => _ProcesoHigieneBloqueState();
}

class _ProcesoHigieneBloqueState extends State<_ProcesoHigieneBloque> {
  final List<String> _utensilios = [];
  final TextEditingController _instruccionesCtrl = TextEditingController();
  final TextEditingController _chipInputCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _instruccionesCtrl.dispose();
    _chipInputCtrl.dispose();
    super.dispose();
  }

  bool get _sinInfo =>
      widget.config == null ||
      (widget.config!.utensilios.isEmpty &&
          widget.config!.instrucciones == null);

  Future<void> _guardarProceso() async {
    setState(() => _guardando = true);
    final base = widget.config;
    final updated = ModuloHigieneConfig(
      configurado: base?.configurado ?? false,
      frecuenciaDias: base?.frecuenciaDias ?? 0,
      notificacionActiva: base?.notificacionActiva ?? false,
      idNotificacion: base?.idNotificacion,
      proximoAviso: base?.proximoAviso,
      utensilios: _utensilios,
      instrucciones: _instruccionesCtrl.text.trim().isEmpty
          ? null
          : _instruccionesCtrl.text.trim(),
    );
    await widget.fs.saveModuloHigieneConfig(
      widget.familiaID,
      widget.mascota.mascotaID,
      updated,
    );
    if (mounted) setState(() => _guardando = false);
  }

  void _agregarChip() {
    final texto = _chipInputCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() {
      _utensilios.add(texto);
      _chipInputCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightSecondary.withAlpha(70),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.clipboardList,
                size: 18,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¿Cómo bañar a ${widget.mascota.nombre}?',
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.secondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_sinInfo) ...[
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chipInputCtrl,
                  style: const TextStyle(fontFamily: 'Nunito'),
                  decoration: _pawnerInput(hint: 'Agregar utensilio…'),
                  onSubmitted: (_) => _agregarChip(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _agregarChip,
                child: const Text('Agregar'),
              ),
            ],
          ),
          if (_utensilios.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _utensilios
                  .map(
                    (u) => Chip(
                      label: Text(
                        u,
                        style: const TextStyle(fontFamily: 'Nunito', fontSize: 13),
                      ),
                      backgroundColor: AppColors.lightSecondary.withAlpha(60),
                      deleteIcon: const Icon(LucideIcons.x, size: 14),
                      side: BorderSide.none,
                      onDeleted: () => setState(() => _utensilios.remove(u)),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _instruccionesCtrl,
            maxLines: null,
            minLines: 3,
            style: const TextStyle(fontFamily: 'Nunito'),
            decoration:
                _pawnerInput(hint: 'Describe el proceso paso a paso…'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: _primaryButtonStyle(),
              onPressed: _guardando ? null : _guardarProceso,
              child: _guardando
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar proceso'),
            ),
          ),
        ] else ...[
          Container(
            decoration: _cardDecoration(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.config!.utensilios.isNotEmpty) ...[
                  const Text(
                    'Utensilios',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: widget.config!.utensilios
                        .map(
                          (u) => Chip(
                            label: Text(
                              u,
                              style: const TextStyle(
                                fontFamily: 'Nunito',
                                fontSize: 13,
                              ),
                            ),
                            backgroundColor:
                                AppColors.lightSecondary.withAlpha(60),
                            side: BorderSide.none,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.config!.instrucciones != null) ...[
                  const Text(
                    'Instrucciones',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.config!.instrucciones!,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                  ),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      textStyle: const TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        backgroundColor: Colors.white,
                        builder: (_) => HigieneContextoSheet(
                          familiaID: widget.familiaID,
                          mascotaID: widget.mascota.mascotaID,
                          config: widget.config!,
                          onSaved: () {},
                        ),
                      );
                    },
                    child: const Text('Editar proceso'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ── Bloque 3: Historial de baños ─────────────────────────────────────────────

class _HistorialBanosBloque extends StatelessWidget {
  final Mascota mascota;
  final String familiaID;
  final ModuloHigieneConfig? config;
  final List<RegistroBano> banos;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final void Function(DateTime focused, DateTime? selected) onDayChanged;
  final FirestoreService fs;

  const _HistorialBanosBloque({
    required this.mascota,
    required this.familiaID,
    required this.config,
    required this.banos,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDayChanged,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.lightSecondary.withAlpha(70),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.history,
                size: 18,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Historial de baños',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: _cardDecoration(),
          padding: const EdgeInsets.all(8),
          child: TableCalendar<RegistroBano>(
            firstDay: DateTime(2020),
            lastDay: DateTime.now(),
            focusedDay: focusedDay,
            selectedDayPredicate: (d) => isSameDay(selectedDay, d),
            eventLoader: (d) =>
                banos.where((b) => isSameDay(b.fecha, d)).toList(),
            onDaySelected: (selected, focused) {
              final tieneBano = banos.any((b) => isSameDay(b.fecha, selected));
              onDayChanged(focused, tieneBano ? selected : null);
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(50),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                fontFamily: 'Nunito',
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
              selectedTextStyle: const TextStyle(
                fontFamily: 'Nunito',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              defaultTextStyle: const TextStyle(fontFamily: 'Nunito'),
              weekendTextStyle: const TextStyle(fontFamily: 'Nunito'),
              outsideTextStyle: TextStyle(
                fontFamily: 'Nunito',
                color: Colors.grey.shade400,
              ),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              weekendStyle: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: AppColors.secondary,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.secondary,
              ),
              leftChevronIcon: Icon(
                LucideIcons.chevronLeft,
                color: AppColors.secondary,
                size: 20,
              ),
              rightChevronIcon: Icon(
                LucideIcons.chevronRight,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
            availableGestures: AvailableGestures.none,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (ctx, day, events) {
                if (events.isEmpty) return null;
                return const Positioned(
                  bottom: 1,
                  child: Text('🛁', style: TextStyle(fontSize: 14)),
                );
              },
            ),
          ),
        ),
        if (selectedDay != null) ...[
          const SizedBox(height: 12),
          Dismissible(
            key: ValueKey(
              banos.firstWhere((b) => isSameDay(b.fecha, selectedDay)).id,
            ),
            direction: DismissDirection.horizontal,
            background: const SizedBox.shrink(),
            secondaryBackground: const SizedBox.shrink(),
            onDismissed: (_) => onDayChanged(focusedDay, null),
            child: _BanoCard(
              bano: banos.firstWhere((b) => isSameDay(b.fecha, selectedDay)),
              familiaID: familiaID,
              mascotaID: mascota.mascotaID,
              config: config,
              fs: fs,
            ),
          ),
        ],
        if (banos.isEmpty) ...[
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Text('🛁', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Text(
                  'Aún no hay baños registrados',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _BanoCard extends StatelessWidget {
  final RegistroBano bano;
  final String familiaID;
  final String mascotaID;
  final ModuloHigieneConfig? config;
  final FirestoreService fs;

  const _BanoCard({
    required this.bano,
    required this.familiaID,
    required this.mascotaID,
    required this.config,
    required this.fs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(bano.fecha),
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < bano.calidad ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          if (bano.notas != null) ...[
            const SizedBox(height: 6),
            Text(
              bano.notas!,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 13,
                color: Colors.black54,
              ),
            ),
          ],
          if (bano.urlFoto != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                bano.urlFoto!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: double.infinity,
                    height: 180,
                    color: AppColors.inputBackground,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.secondary,
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.wifiOff,
                        color: Colors.grey.shade400,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sin conexión',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  if (config == null) return;
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    backgroundColor: Colors.white,
                    builder: (_) => EditBanoSheet(
                      familiaID: familiaID,
                      mascotaID: mascotaID,
                      bano: bano,
                      config: config!,
                      onSaved: () {},
                    ),
                  );
                },
                child: const Text('Editar'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        'Eliminar baño',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: const Text(
                        '¿Eliminar este registro? Esta acción no se puede deshacer.',
                        style: TextStyle(fontFamily: 'Nunito'),
                      ),
                      actions: [
                        TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontFamily: 'Nunito'),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(context);
                            await fs.deleteBano(familiaID, mascotaID, bano.id);
                          },
                          child: const Text(
                            'Eliminar',
                            style: TextStyle(
                              fontFamily: 'Nunito',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
