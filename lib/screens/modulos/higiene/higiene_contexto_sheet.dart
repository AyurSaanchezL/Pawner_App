import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/modulo_higiene/modulo_higiene_config.dart';
import 'package:pawner_app/services/firestore_service.dart';

InputDecoration _pawnerInput({String? label, String? hint}) => InputDecoration(
      labelText: label,
      hintText: hint,
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

class HigieneContextoSheet extends StatefulWidget {
  final String familiaID;
  final String mascotaID;
  final ModuloHigieneConfig config;
  final VoidCallback onSaved;
  final FirestoreService? fsOverride;

  const HigieneContextoSheet({
    required this.familiaID,
    required this.mascotaID,
    required this.config,
    required this.onSaved,
    this.fsOverride,
    super.key,
  });

  @override
  State<HigieneContextoSheet> createState() => _HigieneContextoSheetState();
}

class _HigieneContextoSheetState extends State<HigieneContextoSheet> {
  late List<String> _utensilios;
  late TextEditingController _instruccionesCtrl;
  final TextEditingController _chipInputCtrl = TextEditingController();
  bool _guardando = false;

  FirestoreService get _fs => widget.fsOverride ?? FirestoreService();

  @override
  void initState() {
    super.initState();
    _utensilios = List<String>.from(widget.config.utensilios);
    _instruccionesCtrl = TextEditingController(
      text: widget.config.instrucciones ?? '',
    );
  }

  @override
  void dispose() {
    _instruccionesCtrl.dispose();
    _chipInputCtrl.dispose();
    super.dispose();
  }

  void _agregarChip() {
    final texto = _chipInputCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() {
      _utensilios.add(texto);
      _chipInputCtrl.clear();
    });
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final updated = ModuloHigieneConfig(
      configurado: widget.config.configurado,
      frecuenciaDias: widget.config.frecuenciaDias,
      notificacionActiva: widget.config.notificacionActiva,
      idNotificacion: widget.config.idNotificacion,
      proximoAviso: widget.config.proximoAviso,
      utensilios: _utensilios,
      instrucciones: _instruccionesCtrl.text.trim().isEmpty
          ? null
          : _instruccionesCtrl.text.trim(),
    );
    await _fs.saveModuloHigieneConfig(
      widget.familiaID,
      widget.mascotaID,
      updated,
    );
    widget.onSaved();
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
                  'Proceso de higiene',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Utensilios
                const Text(
                  'Utensilios',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chipInputCtrl,
                        style: const TextStyle(fontFamily: 'Nunito'),
                        decoration: _pawnerInput(
                          hint: 'Ej. champú antipulgas, cepillo…',
                        ),
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
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _utensilios
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
                            deleteIcon: const Icon(LucideIcons.x, size: 14),
                            side: BorderSide.none,
                            onDeleted: () =>
                                setState(() => _utensilios.remove(u)),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),

                // Instrucciones
                const Text(
                  'Instrucciones',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _instruccionesCtrl,
                  maxLines: null,
                  minLines: 3,
                  style: const TextStyle(fontFamily: 'Nunito'),
                  decoration: _pawnerInput(
                    hint: 'Describe el proceso paso a paso…',
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                        textStyle: const TextStyle(fontFamily: 'Nunito'),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: _guardando ? null : _guardar,
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
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
