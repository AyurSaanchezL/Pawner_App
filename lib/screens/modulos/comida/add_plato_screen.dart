import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/modulo_comida/plato_model.dart';
import 'package:pawner_app/services/cloudinary_service.dart';
import 'package:pawner_app/services/firestore_service.dart';

class AddPlatoScreen extends StatefulWidget {
  final String familiaId;
  final String mascotaId;

  const AddPlatoScreen({
    super.key,
    required this.familiaId,
    required this.mascotaId,
  });

  @override
  State<AddPlatoScreen> createState() => _AddPlatoScreenState();
}

class _AddPlatoScreenState extends State<AddPlatoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _ingredienteController = TextEditingController();
  final _preparacionController = TextEditingController();

  String _tipoSeleccionado = 'Seca';
  final List<String> _tiposComida = ['Seca', 'Húmeda', 'Natural', 'Suplemento'];

  List<String> _ingredientes = [];
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _addIngrediente() {
    if (_ingredienteController.text.isNotEmpty) {
      setState(() {
        _ingredientes.add(_ingredienteController.text.trim());
        _ingredienteController.clear();
      });
    }
  }

  void _removeIngrediente(int index) {
    setState(() {
      _ingredientes.removeAt(index);
    });
  }

  Future<void> _guardarPlato() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    String imageUrl = '';
    if (_imageFile != null) {
      final url = await CloudinaryService().uploadImage(_imageFile!);
      if (url != null) {
        imageUrl = url;
      }
    }

    final preparacion = _preparacionController.text.trim();
    final plato = Plato(
      id: '',
      nombre: _nombreController.text.trim(),
      tipo: _tipoSeleccionado,
      ingredientes: _ingredientes,
      preparacion: preparacion.isNotEmpty ? preparacion : null,
      fotoUrl: imageUrl.isNotEmpty ? imageUrl : null,
      esSugerencia: false,
    );

    await FirestoreService().addPlato(
      widget.familiaId,
      widget.mascotaId,
      plato,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Añadir Plato'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.dark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          image: _imageFile != null
                              ? DecorationImage(
                                  image: FileImage(_imageFile!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _imageFile == null
                            ? const Center(
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Plato',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingresa un nombre';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _tipoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Comida',
                        border: OutlineInputBorder(),
                      ),
                      items: _tiposComida.map((tipo) {
                        return DropdownMenuItem(value: tipo, child: Text(tipo));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _tipoSeleccionado = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ingredienteController,
                            decoration: const InputDecoration(
                              labelText: 'Ingrediente',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: AppColors.secondary,
                            size: 36,
                          ),
                          onPressed: _addIngrediente,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      children: _ingredientes.asMap().entries.map((entry) {
                        return Chip(
                          label: Text(entry.value),
                          onDeleted: () => _removeIngrediente(entry.key),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _preparacionController,
                      maxLines: 4,
                      minLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Preparación / especificaciones',
                        hintText:
                            'Modo de preparación, temperatura, cantidad...',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _guardarPlato,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'GUARDAR PLATO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
