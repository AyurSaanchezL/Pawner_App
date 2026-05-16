import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/modulo_comida/plato_model.dart';
import 'package:pawner_app/services/firestore_service.dart';

class DetallePlatoSheet extends StatefulWidget {
  final Plato plato;
  final String familiaId;
  final String mascotaId;

  const DetallePlatoSheet({
    super.key,
    required this.plato,
    required this.familiaId,
    required this.mascotaId,
  });

  @override
  State<DetallePlatoSheet> createState() => _DetallePlatoSheetState();
}

class _DetallePlatoSheetState extends State<DetallePlatoSheet> {
  late Plato _plato;

  @override
  void initState() {
    super.initState();
    _plato = widget.plato;
  }

  Color _colorParaTipo(String tipo) {
    switch (tipo) {
      case 'Seca':
        return Colors.amber.shade600;
      case 'Húmeda':
        return Colors.blue.shade400;
      case 'Natural':
        return Colors.green.shade500;
      case 'Suplemento':
        return AppColors.secondary;
      default:
        return Colors.grey;
    }
  }

  void _abrirEditar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPlatoSheet(
        plato: _plato,
        familiaId: widget.familiaId,
        mascotaId: widget.mascotaId,
        onSaved: (updated) => setState(() => _plato = updated),
      ),
    );
  }

  void _confirmarEliminar() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar plato',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Seguro que quieres eliminar "${_plato.nombre}"?',
          style: const TextStyle(fontFamily: 'Nunito'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(fontFamily: 'Nunito', color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () async {
              final sheetNav = Navigator.of(context);
              await FirestoreService().deletePlato(widget.familiaId, widget.mascotaId, _plato.id);
              if (ctx.mounted) Navigator.pop(ctx);
              sheetNav.pop();
            },
            child: const Text(
              'Eliminar',
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

  @override
  Widget build(BuildContext context) {
    final color = _colorParaTipo(_plato.tipo);
    final hasImage = _plato.fotoUrl != null && _plato.fotoUrl!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: hasImage
                    ? Image.network(_plato.fotoUrl!, fit: BoxFit.cover)
                    : Container(
                        color: color.withAlpha(30),
                        child: Center(
                          child: Icon(
                            LucideIcons.chefHat,
                            size: 52,
                            color: color.withAlpha(160),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          _plato.nombre,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _plato.tipo,
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _abrirEditar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.lightSecondary.withAlpha(60),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.edit3,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_plato.ingredientes.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(LucideIcons.list, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        const Text(
                          'Ingredientes',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _plato.ingredientes
                          .map(
                            (ing) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.lightSecondary.withAlpha(50),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                ing,
                                style: const TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ] else
                    Text(
                      'Sin ingredientes registrados',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  if (_plato.preparacion != null && _plato.preparacion!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(LucideIcons.fileText, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        const Text(
                          'Preparación',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _plato.preparacion!,
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _confirmarEliminar,
                      icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                      label: const Text(
                        'Eliminar plato',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w700,
                          color: Colors.redAccent,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
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
}

// --- Edit sheet (patrón _EditPerfilSheet) ---

class _EditPlatoSheet extends StatefulWidget {
  final Plato plato;
  final String familiaId;
  final String mascotaId;
  final void Function(Plato updatedPlato) onSaved;

  const _EditPlatoSheet({
    required this.plato,
    required this.familiaId,
    required this.mascotaId,
    required this.onSaved,
  });

  @override
  State<_EditPlatoSheet> createState() => _EditPlatoSheetState();
}

class _EditPlatoSheetState extends State<_EditPlatoSheet> {
  late TextEditingController _nombreController;
  late TextEditingController _ingredienteController;
  late TextEditingController _preparacionController;
  late String _tipoSeleccionado;
  late List<String> _ingredientes;
  bool _guardando = false;

  static const List<String> _tipos = ['Seca', 'Húmeda', 'Natural', 'Suplemento'];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.plato.nombre);
    _ingredienteController = TextEditingController();
    _preparacionController = TextEditingController(text: widget.plato.preparacion ?? '');
    _tipoSeleccionado = widget.plato.tipo;
    _ingredientes = List<String>.from(widget.plato.ingredientes);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _ingredienteController.dispose();
    _preparacionController.dispose();
    super.dispose();
  }

  Color _colorParaTipo(String tipo) {
    switch (tipo) {
      case 'Seca':
        return Colors.amber.shade600;
      case 'Húmeda':
        return Colors.blue.shade400;
      case 'Natural':
        return Colors.green.shade500;
      case 'Suplemento':
        return AppColors.secondary;
      default:
        return Colors.grey;
    }
  }

  void _agregarIngrediente() {
    final texto = _ingredienteController.text.trim();
    if (texto.isNotEmpty) {
      setState(() {
        _ingredientes.add(texto);
        _ingredienteController.clear();
      });
    }
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    if (nombre.isEmpty) return;

    setState(() => _guardando = true);

    final preparacion = _preparacionController.text.trim();
    final updated = Plato(
      id: widget.plato.id,
      nombre: nombre,
      tipo: _tipoSeleccionado,
      ingredientes: _ingredientes,
      preparacion: preparacion.isNotEmpty ? preparacion : null,
      fotoUrl: widget.plato.fotoUrl,
      esSugerencia: widget.plato.esSugerencia,
    );

    await FirestoreService().updatePlato(widget.familiaId, widget.mascotaId, updated);
    widget.onSaved(updated);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomInset),
      child: SingleChildScrollView(
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
                const Text(
                  'Editar plato',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                if (_guardando)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.secondary,
                    ),
                  )
                else
                  GestureDetector(
                    onTap: _guardar,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Guardar',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Nombre
            const Text(
              'Nombre',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nombreController,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Nombre del plato',
                hintStyle: TextStyle(fontFamily: 'Nunito', color: Colors.grey.shade400),
                filled: true,
                fillColor: AppColors.homeScreenBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Tipo
            const Text(
              'Tipo',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: _tipos.map((tipo) {
                final isSelected = _tipoSeleccionado == tipo;
                final color = _colorParaTipo(tipo);
                return GestureDetector(
                  onTap: () => setState(() => _tipoSeleccionado = tipo),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withAlpha(30) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      tipo,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? color : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Ingredientes
            const Text(
              'Ingredientes',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 10),
            if (_ingredientes.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _ingredientes.asMap().entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.lightSecondary.withAlpha(50),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          entry.value,
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _ingredientes.removeAt(entry.key)),
                          child: const Icon(
                            LucideIcons.x,
                            size: 13,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ingredienteController,
                    style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
                    onSubmitted: (_) => _agregarIngrediente(),
                    decoration: InputDecoration(
                      hintText: 'Añadir ingrediente...',
                      hintStyle: TextStyle(fontFamily: 'Nunito', color: Colors.grey.shade400),
                      filled: true,
                      fillColor: AppColors.homeScreenBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _agregarIngrediente,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.plus, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Preparación / especificaciones
            const Text(
              'Preparación / especificaciones',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _preparacionController,
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 14),
              maxLines: 4,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'Modo de preparación, temperatura, cantidad...',
                hintStyle: TextStyle(fontFamily: 'Nunito', color: Colors.grey.shade400),
                filled: true,
                fillColor: AppColors.homeScreenBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
