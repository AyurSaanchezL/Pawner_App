import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/modulo_higiene/modulo_higiene_config.dart';
import 'package:pawner_app/core/model/modulo_higiene/registro_bano.dart';
import 'package:pawner_app/services/cloudinary_service.dart';
import 'package:pawner_app/services/firestore_service.dart';

InputDecoration _pawnerInput({String? label, String? hint, Widget? suffix}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffix,
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

class EditBanoSheet extends StatefulWidget {
  final String familiaID;
  final String mascotaID;
  final RegistroBano bano;
  final ModuloHigieneConfig config;
  final VoidCallback onSaved;
  final FirestoreService? fsOverride;

  const EditBanoSheet({
    required this.familiaID,
    required this.mascotaID,
    required this.bano,
    required this.config,
    required this.onSaved,
    this.fsOverride,
    super.key,
  });

  @override
  State<EditBanoSheet> createState() => _EditBanoSheetState();
}

class _EditBanoSheetState extends State<EditBanoSheet> {
  late DateTime _fecha;
  late int _calidad;
  late TextEditingController _notasCtrl;
  String? _urlActual;
  File? _imageFile;
  bool _uploading = false;
  bool _guardando = false;

  FirestoreService get _fs => widget.fsOverride ?? FirestoreService();

  @override
  void initState() {
    super.initState();
    _fecha = widget.bano.fecha;
    _calidad = widget.bano.calidad;
    _notasCtrl = TextEditingController(text: widget.bano.notas ?? '');
    _urlActual = widget.bano.urlFoto;
  }

  @override
  void dispose() {
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _seleccionarFoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _imageFile = File(picked.path);
      _uploading = true;
    });
    final url = await CloudinaryService().uploadImage(_imageFile!);
    if (!mounted) return;
    if (url != null) {
      setState(() {
        _urlActual = url;
        _uploading = false;
      });
    } else {
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'No se pudo subir la foto',
            style: TextStyle(fontFamily: 'Nunito'),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _guardar() async {
    if (_calidad == 0 || _uploading) return;
    setState(() => _guardando = true);
    final updated = RegistroBano(
      id: widget.bano.id,
      fecha: _fecha,
      calidad: _calidad,
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      urlFoto: _urlActual,
    );
    await _fs.updateBano(widget.familiaID, widget.mascotaID, updated);
    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  void _confirmarEliminar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Eliminar baño',
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          '¿Eliminar este registro? Esta acción no se puede deshacer.',
          style: TextStyle(fontFamily: 'Nunito'),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(fontFamily: 'Nunito')),
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
              await _fs.deleteBano(
                widget.familiaID,
                widget.mascotaID,
                widget.bano.id,
              );
              widget.onSaved();
              if (mounted) Navigator.pop(context);
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
                  'Editar baño',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Fecha
                GestureDetector(
                  onTap: _seleccionarFecha,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.calendar,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_fecha),
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Calidad
                const Text(
                  'Calidad del baño',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                _CalidadSelector(
                  calidad: _calidad,
                  onChanged: (v) => setState(() => _calidad = v),
                ),
                const SizedBox(height: 16),

                // Notas
                TextField(
                  controller: _notasCtrl,
                  maxLines: 3,
                  style: const TextStyle(fontFamily: 'Nunito'),
                  decoration: _pawnerInput(
                    label: 'Observaciones del baño',
                    hint: 'Opcional…',
                  ),
                ),
                const SizedBox(height: 16),

                // Foto
                const Text(
                  'Foto',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                _FotoEditorSelector(
                  uploading: _uploading,
                  urlActual: _urlActual,
                  onCambiar: _seleccionarFoto,
                  onQuitar: () => setState(() => _urlActual = null),
                  onAgregar: _seleccionarFoto,
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: _confirmarEliminar,
                        child: const Text('Eliminar baño'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        onPressed:
                            (_calidad == 0 || _uploading || _guardando)
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CalidadSelector extends StatelessWidget {
  final int calidad;
  final ValueChanged<int> onChanged;

  const _CalidadSelector({required this.calidad, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (i) => IconButton(
          onPressed: () => onChanged(i + 1),
          icon: Icon(
            i < calidad ? Icons.star : Icons.star_border,
            color: Colors.amber,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _FotoEditorSelector extends StatelessWidget {
  final bool uploading;
  final String? urlActual;
  final VoidCallback onCambiar;
  final VoidCallback onQuitar;
  final VoidCallback onAgregar;

  const _FotoEditorSelector({
    required this.uploading,
    required this.urlActual,
    required this.onCambiar,
    required this.onQuitar,
    required this.onAgregar,
  });

  @override
  Widget build(BuildContext context) {
    if (uploading) {
      return const SizedBox(
        width: 80,
        height: 80,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }
    if (urlActual != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                urlActual!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: onCambiar,
                icon: const Icon(LucideIcons.camera, size: 16),
                label: const Text('Cambiar foto'),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: onQuitar,
                child: const Text('Quitar foto'),
              ),
            ],
          ),
        ],
      );
    }
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.secondary,
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: onAgregar,
      icon: const Icon(LucideIcons.camera),
      label: const Text('Agregar foto'),
    );
  }
}
