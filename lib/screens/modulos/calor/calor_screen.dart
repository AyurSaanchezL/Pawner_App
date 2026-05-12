import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/modulo_calor/modulo_calor_config.dart';
import 'package:pawner_app/core/model/modulo_calor/monitoreo_temperatura.dart';
import 'package:pawner_app/services/firestore_service.dart';

class CalorScreen extends StatefulWidget {
  final Mascota mascota;

  const CalorScreen({super.key, required this.mascota});

  @override
  State<CalorScreen> createState() => _CalorScreenState();
}

class _CalorScreenState extends State<CalorScreen> {
  final FirestoreService _fs = FirestoreService();
  late ModuloCalorConfig _config;
  bool _configLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _fs.getModuloCalorConfig(
      widget.mascota.familiaID,
      widget.mascota.mascotaID,
    );
    if (mounted) {
      setState(() {
        _config =
            config ??
            ModuloCalorConfig.getDefaultForSpecie(widget.mascota.especie);
        _configLoading = false;
      });
    }
  }

  void _registrarTemperatura() {
    showDialog(
      context: context,
      builder: (context) => _DialogoTemperatura(
        config: _config,
        onSave: (temperatura, tipo, prendido, notas) async {
          final monitoreo = MonitoreoTemperatura(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            mascotaID: widget.mascota.mascotaID,
            fecha: DateTime.now(),
            temperaturaActual: temperatura,
            temperaturaOptimaMin: _config.temperaturaOptimaMin,
            temperaturaOptimaMax: _config.temperaturaOptimaMax,
            tipo: tipo,
            dentibroPrendido: prendido,
            notas: notas,
          );
          await _fs.guardarMonitoreoTemperatura(
            widget.mascota.familiaID,
            widget.mascota.mascotaID,
            monitoreo,
          );
          if (mounted) {
            setState(() {});
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Temperatura registrada')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_configLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
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
          "Control Térmico de ${widget.mascota.nombre}",
          style: const TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRangoOptimo(),
                  const SizedBox(height: 20),
                  _buildConfiguracionEquipo(),
                  const SizedBox(height: 20),
                  _buildMonitoreoReciente(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        onPressed: _registrarTemperatura,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildRangoOptimo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Rango Óptimo de Temperatura",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Icon(
                    LucideIcons.snowflake,
                    color: Colors.blue,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${_config.temperaturaOptimaMin}°C",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const Text("Mínima"),
                ],
              ),
              Column(
                children: [
                  const Icon(
                    LucideIcons.thermometer,
                    color: Colors.red,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${_config.temperaturaOptimaMax}°C",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  const Text("Máxima"),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfiguracionEquipo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Equipo de Calefacción",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(
              LucideIcons.lightbulb,
              color: AppColors.secondary,
            ),
            title: const Text("Tipo"),
            subtitle: Text(_config.tipo),
            contentPadding: EdgeInsets.zero,
          ),
          ListTile(
            leading: const Icon(LucideIcons.bell, color: AppColors.secondary),
            title: const Text("Notificaciones"),
            subtitle: Text(
              _config.notificacionesActivas ? "Activadas" : "Desactivadas",
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoreoReciente() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Monitoreo Reciente",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<MonitoreoTemperatura>>(
          stream: _fs.streamMonitoreoTemperatura(
            widget.mascota.familiaID,
            widget.mascota.mascotaID,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text("No hay registros");
            }
            final monitoreos = snapshot.data!.take(5).toList();
            if (monitoreos.isEmpty) {
              return const Text("No hay registros");
            }
            return Column(
              children: monitoreos
                  .map(
                    (mon) => ListTile(
                      leading: Icon(
                        mon.temperaturaEnRango
                            ? LucideIcons.checkCircle
                            : LucideIcons.alertCircle,
                        color: mon.temperaturaEnRango
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Text("${mon.temperaturaActual}°C"),
                      subtitle: Text(
                        "${mon.fecha.day}/${mon.fecha.month}/${mon.fecha.year}",
                      ),
                      trailing: Text(
                        mon.temperaturaEnRango ? "Ok" : "Fuera de rango",
                        style: TextStyle(
                          color: mon.temperaturaEnRango
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _DialogoTemperatura extends StatefulWidget {
  final ModuloCalorConfig config;
  final Function(double temperatura, String tipo, bool prendido, String? notas)
  onSave;

  const _DialogoTemperatura({required this.config, required this.onSave});

  @override
  State<_DialogoTemperatura> createState() => _DialogoTemperaturaState();
}

class _DialogoTemperaturaState extends State<_DialogoTemperatura> {
  final _temperaturaController = TextEditingController();
  final _notasController = TextEditingController();
  late String _selectedTipo;
  bool _prendido = true;

  @override
  void initState() {
    super.initState();
    _selectedTipo = widget.config.tipo;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Registrar Temperatura"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _temperaturaController,
              decoration: const InputDecoration(
                labelText: "Temperatura (°C)",
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedTipo,
              items:
                  [
                        'Lámara de calor',
                        'Almohadilla térmica',
                        'Calentador submergible',
                      ]
                      .map(
                        (tipo) =>
                            DropdownMenuItem(value: tipo, child: Text(tipo)),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _selectedTipo = value!),
              decoration: const InputDecoration(labelText: "Tipo de equipo"),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text("Equipo prendido"),
              value: _prendido,
              onChanged: (value) => setState(() => _prendido = value ?? true),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notasController,
              decoration: const InputDecoration(
                labelText: "Notas (opcional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: () {
            if (_temperaturaController.text.isNotEmpty) {
              widget.onSave(
                double.parse(_temperaturaController.text),
                _selectedTipo,
                _prendido,
                _notasController.text.isEmpty ? null : _notasController.text,
              );
            }
          },
          child: const Text("Guardar"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _temperaturaController.dispose();
    _notasController.dispose();
    super.dispose();
  }
}
