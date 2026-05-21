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

class AddBanoSheet extends StatefulWidget {
  final String familiaID;
  final String mascotaID;
  final ModuloHigieneConfig config;
  final VoidCallback onSaved;
  final FirestoreService? fsOverride;

  const AddBanoSheet({
    required this.familiaID,
    required this.mascotaID,
    required this.config,
    required this.onSaved,
    this.fsOverride,
    super.key,
  });

  @override
  State<AddBanoSheet> createState() => _AddBanoSheetState();
}

class _AddBanoSheetState extends State<AddBanoSheet> {
  DateTime _fecha = DateTime.now();
  int _calidad = 0;
  final TextEditingController _notasCtrl = TextEditingController();
  File? _imageFile;
  String? _uploadedUrl;
  bool _uploading = false;
  bool _guardando = false;

  FirestoreService get _fs => widget.fsOverride ?? FirestoreService();

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
        _uploadedUrl = url;
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

    final bano = RegistroBano(
      id: '',
      fecha: _fecha,
      calidad: _calidad,
      notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
      urlFoto: _uploadedUrl,
    );
    await _fs.addBano(widget.familiaID, widget.mascotaID, bano);

    final banos =
        await _fs.streamBanos(widget.familiaID, widget.mascotaID).first;
    final hayMasReciente = banos.any((b) => b.fecha.isAfter(_fecha));
    if (!hayMasReciente) {
      final hora = widget.config.proximoAviso != null
          ? TimeOfDay.fromDateTime(widget.config.proximoAviso!)
          : const TimeOfDay(hour: 9, minute: 0);
      final nuevoAviso = _calcularProximoAviso(
        _fecha,
        widget.config.frecuenciaDias,
        hora,
      );
      final configActualizado = ModuloHigieneConfig(
        configurado: widget.config.configurado,
        frecuenciaDias: widget.config.frecuenciaDias,
        notificacionActiva: widget.config.notificacionActiva,
        idNotificacion: widget.config.idNotificacion,
        proximoAviso: nuevoAviso,
        utensilios: widget.config.utensilios,
        instrucciones: widget.config.instrucciones,
      );
      await _fs.saveModuloHigieneConfig(
        widget.familiaID,
        widget.mascotaID,
        configActualizado,
      );
    }

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
                  'Registrar baño',
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
                _FotoSelector(
                  uploading: _uploading,
                  uploadedUrl: _uploadedUrl,
                  onAgregar: _seleccionarFoto,
                  onQuitar: () => setState(() {
                    _uploadedUrl = null;
                    _imageFile = null;
                  }),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
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
                    onPressed: (_calidad == 0 || _uploading || _guardando)
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
                        : const Text('Guardar'),
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

class _FotoSelector extends StatelessWidget {
  final bool uploading;
  final String? uploadedUrl;
  final VoidCallback onAgregar;
  final VoidCallback onQuitar;

  const _FotoSelector({
    required this.uploading,
    required this.uploadedUrl,
    required this.onAgregar,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    if (uploading) {
      return const SizedBox(
        width: 80,
        height: 80,
        child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
      );
    }
    if (uploadedUrl != null) {
      return Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              uploadedUrl!,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onQuitar,
            icon: const Icon(LucideIcons.x, color: Colors.redAccent),
            tooltip: 'Quitar foto',
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
