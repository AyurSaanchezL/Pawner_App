import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/modulo_comida/plato_model.dart';
import 'package:pawner_app/services/cloudinary_service.dart';
import 'package:pawner_app/services/firestore_service.dart';

class NuevoPlatoScreen extends StatefulWidget {
  final Mascota mascota;
  final VoidCallback? onGuardado;

  const NuevoPlatoScreen({super.key, required this.mascota, this.onGuardado});

  @override
  State<NuevoPlatoScreen> createState() => _NuevoPlatoScreenState();
}

class _NuevoPlatoScreenState extends State<NuevoPlatoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _ingredientesController = TextEditingController();
  String _tipo = 'Seca';
  File? _image;
  bool _isLoading = false;

  final List<String> _tipos = ['Seca', 'Húmeda', 'Natural', 'Suplemento'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? fotoUrl;
      if (_image != null) {
        fotoUrl = await CloudinaryService().uploadImage(_image!);
      }

      final ingredientes = _ingredientesController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final plato = Plato(
        id: '',
        nombre: _nombreController.text.trim(),
        tipo: _tipo,
        ingredientes: ingredientes,
        fotoUrl: fotoUrl,
        esSugerencia: false,
      );

      await FirestoreService().addPlato(
        widget.mascota.familiaID,
        widget.mascota.mascotaID,
        plato,
      );

      if (mounted) {
        widget.onGuardado?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Nuevo Plato",
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    image: _image != null
                        ? DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _image == null
                      ? const Icon(LucideIcons.camera, size: 40, color: Colors.black54)
                      : null,
                ),
              ),
              const SizedBox(height: 30),
              _buildLabel("Nombre"),
              TextFormField(
                controller: _nombreController,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: "Nombre del plato",
                  filled: true,
                  fillColor: const Color(0xFFE1D5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
                validator: (v) => v == null || v.isEmpty ? "Campo requerido" : null,
              ),
              const SizedBox(height: 20),
              _buildLabel("Tipo"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1D5F9),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _tipo,
                    isExpanded: true,
                    alignment: Alignment.center,
                    items: _tipos.map((t) {
                      return DropdownMenuItem(value: t, child: Center(child: Text(t)));
                    }).toList(),
                    onChanged: (v) => setState(() => _tipo = v!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildLabel("Ingredientes (separados por coma)"),
              TextFormField(
                controller: _ingredientesController,
                textAlign: TextAlign.center,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Ej: Pollo, Arroz, Zanahoria",
                  filled: true,
                  fillColor: const Color(0xFFE1D5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.homeScreenOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Guardar Plato",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Nunito'),
        ),
      ),
    );
  }
}
