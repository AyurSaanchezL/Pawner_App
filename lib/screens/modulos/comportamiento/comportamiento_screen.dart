import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/modulo_comportamiento/modulo_comportamiento_config.dart';
import 'package:pawner_app/core/model/modulo_comportamiento/registro_comportamiento.dart';
import 'package:pawner_app/services/firestore_service.dart';

class ComportamientoScreen extends StatefulWidget {
  final Mascota mascota;

  const ComportamientoScreen({super.key, required this.mascota});

  @override
  State<ComportamientoScreen> createState() => _ComportamientoScreenState();
}

class _ComportamientoScreenState extends State<ComportamientoScreen> {
  final FirestoreService _fs = FirestoreService();
  late ModuloComportamientoConfig _config;
  bool _configLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await _fs.getModuloComportamientoConfig(
      widget.mascota.familiaID,
      widget.mascota.mascotaID,
    );
    if (mounted) {
      setState(() {
        _config =
            config ??
            ModuloComportamientoConfig(
              categoriasActivas:
                  ModuloComportamientoConfig.getCategoriasPorEspecie(
                    widget.mascota.especie,
                  ),
              notificacionesActivas: true,
            );
        _configLoading = false;
      });
    }
  }

  void _registrarComportamiento() {
    showDialog(
      context: context,
      builder: (context) => _DialogoNuevoRegistro(
        mascota: widget.mascota,
        config: _config,
        onSave:
            (
              tipo,
              descripcion,
              categoria,
              intensidad,
              detonante,
              resolucion,
              notas,
            ) async {
              final registro = RegistroComportamiento(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                mascotaID: widget.mascota.mascotaID,
                fecha: DateTime.now(),
                tipo: tipo,
                descripcion: descripcion,
                categoria: categoria,
                intensidad: intensidad,
                detonante: detonante,
                resolucion: resolucion,
                notas: notas,
              );
              await _fs.guardarRegistroComportamiento(
                widget.mascota.familiaID,
                widget.mascota.mascotaID,
                registro,
              );
              if (mounted) {
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comportamiento registrado')),
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
          "Comportamiento de ${widget.mascota.nombre}",
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
                  _buildCategoriasCard(),
                  const SizedBox(height: 20),
                  _buildResumenComportamiento(),
                  const SizedBox(height: 20),
                  _buildHistorialReciente(),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.secondary,
        onPressed: _registrarComportamiento,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoriasCard() {
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
            "Categorías Monitoreadas",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
              fontFamily: 'Nunito',
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _config.categoriasActivas
                .map(
                  (cat) => Chip(
                    label: Text(cat),
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
      ),
    );
  }

  Widget _buildResumenComportamiento() {
    return StreamBuilder<List<RegistroComportamiento>>(
      stream: _fs.streamRegistrosComportamiento(
        widget.mascota.familiaID,
        widget.mascota.mascotaID,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: Text("Sin registros aún")),
          );
        }

        final registros = snapshot.data!;
        final positivos = registros.where((r) => r.tipo == 'Positivo').length;
        final negativos = registros.where((r) => r.tipo == 'Negativo').length;

        return Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(
                      LucideIcons.smile,
                      color: Colors.green,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "$positivos",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const Text("Positivos"),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(LucideIcons.frown, color: Colors.red, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      "$negativos",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const Text("Negativos"),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistorialReciente() {
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
        StreamBuilder<List<RegistroComportamiento>>(
          stream: _fs.streamRegistrosComportamiento(
            widget.mascota.familiaID,
            widget.mascota.mascotaID,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Text("No hay registros");
            }
            final registros = snapshot.data!.take(5).toList();
            if (registros.isEmpty) {
              return const Text("No hay registros");
            }
            return Column(
              children: registros
                  .map(
                    (reg) => ListTile(
                      leading: Icon(
                        reg.tipo == 'Positivo'
                            ? LucideIcons.smile
                            : LucideIcons.frown,
                        color: reg.tipo == 'Positivo'
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Text(reg.descripcion),
                      subtitle: Text(
                        "${reg.categoria} • ${reg.fecha.day}/${reg.fecha.month}",
                      ),
                      trailing: reg.intensidad != null
                          ? Text("${reg.intensidad?.toStringAsFixed(0)}/10")
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

class _DialogoNuevoRegistro extends StatefulWidget {
  final Mascota mascota;
  final ModuloComportamientoConfig config;
  final Function(
    String tipo,
    String desc,
    String cat,
    double? int,
    String? det,
    String? res,
    String? notas,
  )
  onSave;

  const _DialogoNuevoRegistro({
    required this.mascota,
    required this.config,
    required this.onSave,
  });

  @override
  State<_DialogoNuevoRegistro> createState() => _DialogoNuevoRegistroState();
}

class _DialogoNuevoRegistroState extends State<_DialogoNuevoRegistro> {
  late String _selectedTipo;
  late String _selectedCategoria;
  final _descripcionController = TextEditingController();
  final _detonantController = TextEditingController();
  final _resolucionController = TextEditingController();
  final _notasController = TextEditingController();
  double? _intensidad;

  @override
  void initState() {
    super.initState();
    _selectedTipo = 'Positivo';
    _selectedCategoria = widget.config.categoriasActivas.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Registrar Comportamiento"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedTipo,
              items: [
                'Positivo',
                'Negativo',
                'Neutral',
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => _selectedTipo = v!),
              decoration: const InputDecoration(labelText: "Tipo"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedCategoria,
              items: widget.config.categoriasActivas
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoria = v!),
              decoration: const InputDecoration(labelText: "Categoría"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(
                labelText: "Descripción",
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detonantController,
              decoration: const InputDecoration(
                labelText: "Detonante (opcional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _resolucionController,
              decoration: const InputDecoration(
                labelText: "Resolución (opcional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text("Intensidad: "),
                Expanded(
                  child: Slider(
                    value: _intensidad ?? 5,
                    min: 1,
                    max: 10,
                    onChanged: (v) => setState(() => _intensidad = v),
                    divisions: 9,
                  ),
                ),
                Text("${(_intensidad ?? 5).toStringAsFixed(0)}/10"),
              ],
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
            if (_descripcionController.text.isNotEmpty) {
              widget.onSave(
                _selectedTipo,
                _descripcionController.text,
                _selectedCategoria,
                _intensidad,
                _detonantController.text.isEmpty
                    ? null
                    : _detonantController.text,
                _resolucionController.text.isEmpty
                    ? null
                    : _resolucionController.text,
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
    _descripcionController.dispose();
    _detonantController.dispose();
    _resolucionController.dispose();
    _notasController.dispose();
    super.dispose();
  }
}
