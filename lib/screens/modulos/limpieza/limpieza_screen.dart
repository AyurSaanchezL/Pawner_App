import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/modulo_limpieza/modulo_limpieza_config.dart';
import 'package:pawner_app/core/model/modulo_limpieza/sesion_limpieza.dart';
import 'package:pawner_app/services/firestore_service.dart';

class LimpiezaScreen extends StatefulWidget {
  final Mascota mascota;

  const LimpiezaScreen({super.key, required this.mascota});

  @override
  State<LimpiezaScreen> createState() => _LimpiezaScreenState();
}

class _LimpiezaScreenState extends State<LimpiezaScreen> {
  final FirestoreService _fs = FirestoreService();
  late ModuloLimpiezaConfig _config;
  bool _configLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _fs.getModuloLimpiezaConfig(
      widget.mascota.familiaID,
      widget.mascota.mascotaID,
    );
    if (mounted) {
      setState(() {
        _config =
            config ??
            ModuloLimpiezaConfig(
              tiposActivos: ModuloLimpiezaConfig.getDefaultFrecuencia(
                widget.mascota.especie,
              ).keys.toList(),
              notificacionesActivas: true,
              frecuenciaDiasRecomendados:
                  ModuloLimpiezaConfig.getDefaultFrecuencia(
                    widget.mascota.especie,
                  ),
            );
        _configLoading = false;
      });
    }
  }

  void _agregarSesionLimpieza() {
    showDialog(
      context: context,
      builder: (context) => _BuildDialogoNuevaLimpieza(
        mascota: widget.mascota,
        config: _config,
        onSave: (tipo, notas, duracion, producto) async {
          final sesion = SesionLimpieza(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            mascotaID: widget.mascota.mascotaID,
            tipo: tipo,
            fecha: DateTime.now(),
            notas: notas,
            duracionMinutos: duracion,
            completada: true,
            productoUsado: producto,
          );
          await _fs.guardarSesionLimpieza(
            widget.mascota.familiaID,
            widget.mascota.mascotaID,
            sesion,
          );
          if (mounted) {
            setState(() {});
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sesión de limpieza registrada')),
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
          "Higiene de ${widget.mascota.nombre}",
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
                  _buildFrecuenciaRecomendada(),
                  const SizedBox(height: 20),
                  _buildTiposActivosCards(),
                  const SizedBox(height: 20),
                  _buildHistorialSeccion(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        onPressed: _agregarSesionLimpieza,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildFrecuenciaRecomendada() {
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
            "Frecuencia Recomendada",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 15),
          ..._config.frecuenciaDiasRecomendados.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key,
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Cada ${e.value} días",
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      color: Colors.grey[600],
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

  Widget _buildTiposActivosCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tipos de Limpieza",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _config.tiposActivos
              .map(
                (tipo) => Chip(
                  label: Text(tipo),
                  backgroundColor: AppColors.secondary.withOpacity(0.2),
                  labelStyle: const TextStyle(
                    color: AppColors.secondary,
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildHistorialSeccion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Historial Reciente",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<SesionLimpieza>>(
          stream: _fs.streamSesionesLimpieza(
            widget.mascota.familiaID,
            widget.mascota.mascotaID,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text("No hay registros");
            }
            final sesiones = snapshot.data!.take(5).toList();
            if (sesiones.isEmpty) {
              return const Text("No hay registros");
            }
            return Column(
              children: sesiones
                  .map(
                    (sesion) => ListTile(
                      leading: Icon(
                        LucideIcons.droplets,
                        color: AppColors.secondary,
                      ),
                      title: Text(sesion.tipo),
                      subtitle: Text(
                        "${sesion.fecha.day}/${sesion.fecha.month}/${sesion.fecha.year}",
                      ),
                      trailing: sesion.duracionMinutos != null
                          ? Text(
                              "${sesion.duracionMinutos?.toStringAsFixed(0)} min",
                            )
                          : null,
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

class _BuildDialogoNuevaLimpieza extends StatefulWidget {
  final Mascota mascota;
  final ModuloLimpiezaConfig config;
  final Function(String tipo, String? notas, double? duracion, String? producto)
  onSave;

  const _BuildDialogoNuevaLimpieza({
    required this.mascota,
    required this.config,
    required this.onSave,
  });

  @override
  State<_BuildDialogoNuevaLimpieza> createState() =>
      _BuildDialogoNuevaLimpiezaState();
}

class _BuildDialogoNuevaLimpiezaState
    extends State<_BuildDialogoNuevaLimpieza> {
  late String _selectedTipo;
  final _notasController = TextEditingController();
  final _duracionController = TextEditingController();
  final _productoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedTipo = widget.config.tiposActivos.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Registrar Limpieza"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedTipo,
              items: widget.config.tiposActivos
                  .map(
                    (tipo) => DropdownMenuItem(value: tipo, child: Text(tipo)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedTipo = value!),
              decoration: const InputDecoration(labelText: "Tipo de Limpieza"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _duracionController,
              decoration: const InputDecoration(
                labelText: "Duración (minutos)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _productoController,
              decoration: const InputDecoration(
                labelText: "Producto usado (opcional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notasController,
              decoration: const InputDecoration(
                labelText: "Notas (opcional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
            widget.onSave(
              _selectedTipo,
              _notasController.text.isEmpty ? null : _notasController.text,
              _duracionController.text.isEmpty
                  ? null
                  : double.parse(_duracionController.text),
              _productoController.text.isEmpty
                  ? null
                  : _productoController.text,
            );
          },
          child: const Text("Guardar"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _notasController.dispose();
    _duracionController.dispose();
    _productoController.dispose();
    super.dispose();
  }
}
