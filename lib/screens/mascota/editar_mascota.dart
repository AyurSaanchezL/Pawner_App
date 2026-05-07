import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/constants.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/services/cloudinary_service.dart';
import 'package:pawner_app/services/firestore_service.dart';

class EditarMascotaScreen extends StatefulWidget {
  final Mascota mascota;

  const EditarMascotaScreen({super.key, required this.mascota});

  @override
  State<EditarMascotaScreen> createState() => _EditarMascotaScreenState();
}

class _EditarMascotaScreenState extends State<EditarMascotaScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nombreController;
  late TextEditingController _chipController;
  late TextEditingController _pesoController;
  late TextEditingController _fechaController;
  late TextEditingController _observacionesController;

  late DateTime _selectedDate;
  late bool _esterilizado;
  late String _genero;
  late String _especie;
  late String _raza;
  bool _isLoading = false;
  File? _image;

  // late Color _lavenderInput = const Color(0xFFE1D5F9); // Replaced with AppColors.inputBackground
  // late Color _orangeButton = const Color(0xFFFFCC80); // Replaced with AppColors.primaryButton

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.mascota.nombre);
    _chipController = TextEditingController(text: widget.mascota.chip);
    _pesoController = TextEditingController(text: widget.mascota.peso.toString());
    _selectedDate = widget.mascota.fechaNacimiento;
    _fechaController = TextEditingController(text: "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}");
    _observacionesController = TextEditingController(text: widget.mascota.observaciones);
    _esterilizado = widget.mascota.esterilizado;
    _genero = widget.mascota.genero;
    _especie = widget.mascota.especie;
    if (!Constants.especiesYRazas.containsKey(_especie)) {
      _especie = 'Otro';
    }
    
    _raza = widget.mascota.raza;
    if (!Constants.especiesYRazas[_especie]!.contains(_raza)) {
      _raza = Constants.especiesYRazas[_especie]!.first;
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.secondary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _fechaController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _actualizarMascota() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String fotoUrl = widget.mascota.fotoUrl;
      if (_image != null) {
        fotoUrl = await CloudinaryService().uploadImage(_image!) ?? fotoUrl;
      }

      final mascotaActualizada = Mascota(
        mascotaID: widget.mascota.mascotaID,
        nombre: _nombreController.text.trim(),
        especie: _especie,
        raza: _raza,
        chip: _chipController.text.trim(),
        peso: double.tryParse(_pesoController.text.trim()) ?? 0.0,
        fechaNacimiento: _selectedDate,
        genero: _genero,
        esterilizado: _esterilizado,
        observaciones: _observacionesController.text.trim(),
        fotoUrl: fotoUrl,
        familiaID: widget.mascota.familiaID,
      );

      await FirestoreService().actualizarMascota(mascotaActualizada);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("¡Mascota actualizada con éxito!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, mascotaActualizada);
      }
    } catch (e) {
      log("Error al actualizar mascota: $e");
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
        title: const Text("Editar Mascota", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Selector de Imagen
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        image: _image != null 
                          ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                          : (widget.mascota.fotoUrl.isNotEmpty 
                              ? DecorationImage(
                                  image: widget.mascota.fotoUrl.startsWith('http')
                                      ? NetworkImage(widget.mascota.fotoUrl)
                                      : AssetImage(widget.mascota.fotoUrl) as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : null),
                      ),
                      child: (_image == null && widget.mascota.fotoUrl.isEmpty)
                        ? const Icon(LucideIcons.plus, size: 50, color: Colors.black54)
                        : null,
                    ),
                  ),
                  if (_image != null || widget.mascota.fotoUrl.isNotEmpty)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.pencil, size: 20, color: Colors.white),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),
              
              _buildLabel("Nombre"),
              _buildTextField(_nombreController, "Nombre de tu mascota"),

              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildLabel("Especie"),
                        _buildDropdown(
                          value: _especie,
                          items: Constants.especiesYRazas.keys.toList(),
                          onChanged: (val) {
                            setState(() {
                              _especie = val!;
                              // Resetear raza si cambia la especie
                              _raza = Constants.especiesYRazas[_especie]!.first;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      children: [
                        _buildLabel("Raza"),
                        _buildDropdown(
                          value: _raza,
                          items: Constants.especiesYRazas[_especie]!,
                          onChanged: (val) => setState(() => _raza = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              _buildLabel("Chip"),
              _buildTextField(_chipController, "Número de chip"),

              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLabel("Peso"),
                        _buildTextField(_pesoController, "kg", isNumber: true),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLabel("F. Nacimiento"),
                        _buildDateField(),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGenderSelector(),
                  _buildSterilizedSelectorSection(),
                ],
              ),

              const SizedBox(height: 20),
              _buildLabel("Observaciones"),
              _buildTextField(_observacionesController, "Notas sobre tu mascota...", maxLines: 4, isOptional: true),

              const SizedBox(height: 40),
              // Botón Guardar
              _isLoading
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _actualizarMascota,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.homeScreenOrange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        "Guardar Cambios",
                        style: TextStyle(
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

  Widget _buildGenderSelector() {
    return Column(
      children: [
        _buildLabel("Género"),
        Row(
          children: [
            _circularOption(
              icon: Icons.male,
              isSelected: _genero == 'Macho',
              onTap: () => setState(() => _genero = 'Macho'),
              color: Colors.blue.shade200,
            ),
            const SizedBox(width: 10),
            _circularOption(
              icon: Icons.female,
              isSelected: _genero == 'Hembra',
              onTap: () => setState(() => _genero = 'Hembra'),
              color: Colors.pink.shade200,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSterilizedSelectorSection() {
    return Column(
      children: [
        _buildLabel("Esterilizado"),
        Row(
          children: [
            _circularOption(
              icon: LucideIcons.scissors,
              isSelected: _esterilizado,
              onTap: () => setState(() => _esterilizado = true),
              color: Colors.green.shade200,
              showCheck: true,
            ),
            const SizedBox(width: 10),
            _circularOption(
              icon: LucideIcons.scissors,
              isSelected: !_esterilizado,
              onTap: () => setState(() => _esterilizado = false),
              color: Colors.red.shade200,
              showX: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(25),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          alignment: Alignment.center,
          style: Constants.inputStyle.copyWith(color: Colors.black),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Center(child: Text(item)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isNumber = false, int maxLines = 1, bool isOptional = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
      maxLines: maxLines,
      textAlign: TextAlign.center,
      style: Constants.inputStyle,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      validator: (value) {
        if (isOptional) return null;
        return value == null || value.isEmpty ? "Campo requerido" : null;
      },
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _fechaController,
      readOnly: true,
      textAlign: TextAlign.center,
      onTap: () => _selectDate(context),
      decoration: InputDecoration(
        prefixIcon: const Icon(LucideIcons.calendar, color: Colors.black54),
        hintText: "Día/Mes/Año",
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      validator: (value) => value == null || value.isEmpty ? "Campo requerido" : null,
    );
  }

  Widget _circularOption({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
    bool showCheck = false,
    bool showX = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color : AppColors.inputBackground, // todo -> revisar
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
            ),
            child: Icon(icon, color: isSelected ? Colors.white : Colors.black54),
          ),
          if (showCheck)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 12, color: Colors.green),
              ),
            ),
          if (showX)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 12, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
