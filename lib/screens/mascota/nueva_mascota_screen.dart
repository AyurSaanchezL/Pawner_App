import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/constants.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/services/auth_service.dart';
import 'package:pawner_app/services/cloudinary_service.dart';
import 'package:pawner_app/services/firestore_service.dart';

class NuevaMascotaScreen extends StatefulWidget {
  const NuevaMascotaScreen({super.key});

  @override
  State<NuevaMascotaScreen> createState() => _NuevaMascotaScreenState();
}

class _NuevaMascotaScreenState extends State<NuevaMascotaScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _chipController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _observacionesController =
      TextEditingController();

  String? _selectedEspecie;
  String? _selectedRaza;
  DateTime _selectedDate = DateTime.now();
  String _genero = 'Macho'; // 'Macho' o 'Hembra'
  bool _esterilizado = false;
  bool _isLoading = false;
  File? _image;

  final Color _lavenderInput = const Color(0xFFE1D5F9);
  final Color _orangeButton = const Color(0xFFFFCC80);

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

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
            colorScheme: ColorScheme.light(primary: AppColors.secondary),
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

  Future<void> _guardarMascota() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedEspecie == null || _selectedRaza == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor selecciona especie y raza"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      Usuario usuarioActual = await authService.value.getCurrentUser();

      if (usuarioActual.familiaID == null || usuarioActual.familiaID!.isEmpty) {
        throw Exception("No tienes una familia asignada.");
      }

      String fotoUrl = "";
      if (_image != null) {
        fotoUrl = await CloudinaryService().uploadImage(_image!) ?? "";
      }

      final nuevaMascota = Mascota(
        mascotaID: '', // Firestore generará el ID
        nombre: _nombreController.text.trim(),
        especie: _selectedEspecie!,
        raza: _selectedRaza!,
        chip: _chipController.text.trim(),
        peso: double.tryParse(_pesoController.text.trim()) ?? 0.0,
        fechaNacimiento: _selectedDate,
        genero: _genero,
        esterilizado: _esterilizado,
        observaciones: _observacionesController.text.trim(),
        fotoUrl: fotoUrl,
        familiaID: usuarioActual.familiaID!,
        modulos: [],
      );

      await FirestoreService().crearMascota(nuevaMascota);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡Mascota guardada con éxito!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      log("Error al guardar mascota: $e");
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
          icon: const Icon(
            LucideIcons.chevronLeft,
            color: Colors.black,
            size: 30,
          ),
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
              // Selector de Imagen
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary, // Crema
                    border: Border.all(color: Colors.black54, width: 2),
                    shape: BoxShape.circle,
                    image: _image != null
                        ? DecorationImage(
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _image == null
                      ? const Icon(
                          LucideIcons.plus,
                          size: 50,
                          color: Colors.black54,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              // Texto de Bienvenida
              const Text(
                "Bieeen!! Nos alegramos mucho!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Formulario
              _buildLabel("Nombre"),
              _buildTextField(
                _nombreController,
                "Nombre de tu mascota",
                maxLength: 20,
              ),

              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildLabel("Especie"),
                        _buildDropdown(
                          value: _selectedEspecie,
                          hint: "Especie",
                          items: Constants.especiesYRazas.keys.toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedEspecie = val;
                              if (val == 'Otro') {
                                _selectedRaza = 'Otro';
                              } else {
                                _selectedRaza =
                                    null; // Reset raza when especie changes
                              }
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
                          value: _selectedRaza,
                          hint: "Raza",
                          items: _selectedEspecie != null
                              ? Constants.especiesYRazas[_selectedEspecie]!
                              : [],
                          onChanged: (val) {
                            setState(() {
                              _selectedRaza = val;
                            });
                          },
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
                children: [_buildGenderSelector(), _buildSterilizedSelector()],
              ),

              const SizedBox(height: 20),
              _buildLabel("Observaciones"),
              _buildTextField(
                _observacionesController,
                "Notas sobre tu mascota...",
                maxLines: 4,
                isOptional: true,
              ),

              const SizedBox(height: 30),
              // Botón Guardar
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _guardarMascota,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orangeButton,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 4, // Añadida sombra para que destaque
                        ),
                        child: const Text(
                          "Guardar",
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

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: _lavenderInput,
        borderRadius: BorderRadius.circular(25),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.black54)),
          isExpanded: true,
          icon: const Icon(LucideIcons.chevronDown, size: 20),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: Constants.inputStyle),
            );
          }).toList(),
          onChanged: onChanged,
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
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
    bool isOptional = false,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? TextInputType.number
          : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
      maxLines: maxLines,
      textAlign: TextAlign.center,
      style: Constants.inputStyle,
      inputFormatters: maxLength != null
          ? [LengthLimitingTextInputFormatter(maxLength)]
          : null,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: _lavenderInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
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
        fillColor: _lavenderInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? "Campo requerido" : null,
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

  Widget _buildSterilizedSelector() {
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
              color: isSelected ? color : _lavenderInput,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
          if (showCheck)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.green),
              ),
            ),
          if (showX)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
