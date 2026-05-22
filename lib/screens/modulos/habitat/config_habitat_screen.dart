import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/components/number_picker.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/modulo_habitat/dynamic_param_input.dart';
import 'package:pawner_app/core/model/modulo_habitat/modulo_habitat_config.dart';
import 'package:pawner_app/services/firestore_service.dart';
import 'package:pawner_app/services/notification_service.dart';

class ConfigHabitatScreen extends StatefulWidget {
  final Mascota mascota;
  final HabitatConfig?
  config; // Si es null, significa que es la primera configuración
  final bool isEditing;
  final VoidCallback onSaved;

  const ConfigHabitatScreen({
    super.key,
    required this.mascota,
    this.config,
    required this.isEditing,
    required this.onSaved,
  });

  @override
  State<ConfigHabitatScreen> createState() => _ConfigHabitatScreenState();
}

class _ConfigHabitatScreenState extends State<ConfigHabitatScreen> {
  final TextEditingController preferenciasController = TextEditingController();
  final TextEditingController tipoHabitatController = TextEditingController();
  int intervaloLimpieza = 5;
  final List<DynamicParamInput> _dynamicParams = [];
  Map<String, dynamic> parametrosIdeales = {};

  @override
  void initState() {
    super.initState();
    if (widget.config != null) {
      tipoHabitatController.text = widget.config!.tipoHabitat;
      preferenciasController.text = widget.config!.preferencias;
      parametrosIdeales = widget.config!.parametrosIdeales;
      intervaloLimpieza = widget.config!.intervaloLimpieza;

      if (parametrosIdeales.isNotEmpty) {
        parametrosIdeales.forEach((key, value) {
          DynamicParamInput paramInput = DynamicParamInput();
          paramInput.keyController.text = key;
          paramInput.valueController.text = value.toString();

          _dynamicParams.add(paramInput);
        });
      }
    } else {
      // Si es nueva configuración, añadimos un campo dinámico vacío por defecto
      _dynamicParams.add(DynamicParamInput());
    }
  }

  @override
  void dispose() {
    tipoHabitatController.dispose();
    preferenciasController.dispose();
    for (var param in _dynamicParams) {
      param.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // ------ ICONO CIRCULAR
            Container(
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.homeScreenOrange, width: 1.5),
                ),
              ),
              child: const Icon(
                LucideIcons.home,
                color: AppColors.homeScreenOrange,
                size: 60,
              ),
            ),
            const SizedBox(height: 15),
            // ------ TÍTULO
            const Text(
              "Configura el hábitat ideal para tu mascota",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            // ------ TIPO DE HÁBITAT
            TextField(
              controller: tipoHabitatController,
              decoration: InputDecoration(
                labelText: "Tipo de hábitat: acuario, terrario...",
                filled: true,
                fillColor: AppColors.inputBackground.withAlpha(180),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            // ------ PARÁMETROS IDEALES
            _buildParametrosIdealesSection(),
            // ------ PREFERENCIAS ADICIONALES
            TextField(
              controller: preferenciasController,
              minLines: 3,
              maxLines: 3,
              decoration: InputDecoration(
                alignLabelWithHint: true,
                hintText: "Ej: Prefiere arena fina, necesita escondites...",
                labelText: "Preferencias adicionales",
                filled: true,
                fillColor: AppColors.inputBackground.withAlpha(180),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ------ INTERVALO DE LIMPIEZA (¡Ya no se va a trabar!)
            Row(
              spacing: 30,
              children: [
                Text(
                  "Intervalo de limpieza (días):",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                CustomNumberPicker(
                  context: context,
                  label: "",
                  backgroundColor: AppColors.inputBackground.withAlpha(180),
                  val: intervaloLimpieza,
                  min: 1,
                  max: 30,
                  onChanged: (val) => setState(() => intervaloLimpieza = val),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => _saveHabitatConfig(widget.mascota),
                style: ElevatedButton.styleFrom(
                  elevation: 3,
                  backgroundColor: AppColors.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  "GUARDAR CONFIGURACIÓN",
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametrosIdealesSection() {
    return Column(
      children: [
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Parámetros ideales",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _dynamicParams.add(DynamicParamInput());
                });
              },
              icon: const Icon(
                Icons.add,
                color: AppColors.homeScreenOrange,
                fontWeight: .w600,
              ),
              label: const Text(
                "Añadir",
                style: TextStyle(
                  color: AppColors.homeScreenOrange,
                  fontWeight: .w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Renderizado de los campos agregados
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _dynamicParams.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  // Campo Clave (Ej: ph_ideal)
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _dynamicParams[index].keyController,
                      maxLength: 14,
                      decoration: InputDecoration(
                        counterText: "",
                        hintText: "Ej: pH ideal",
                        hintStyle: TextStyle(
                          color: AppColors.dark.withAlpha(150),
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                        labelText: "Parámetro",
                        filled: true,
                        fillColor: AppColors.inputBackground.withAlpha(140),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Campo Valor (Ej: 7.2)
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _dynamicParams[index].valueController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: "Ej: 7.2",
                        hintStyle: TextStyle(
                          color: AppColors.dark.withAlpha(150),
                          fontStyle: FontStyle.italic,
                          fontSize: 13,
                        ),
                        labelText: "Valor",
                        filled: true,
                        fillColor: AppColors.inputBackground.withAlpha(140),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  // Botón para eliminar fila si se arrepienten
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      setState(() {
                        _dynamicParams[index].dispose();
                        _dynamicParams.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _saveHabitatConfig(Mascota m) async {
    Map<String, dynamic> parametrosIdeales = {};

    for (var param in _dynamicParams) {
      log(param.keyController.text);
      String key = param.keyController.text.trim();
      String value = param.valueController.text.trim();

      if (key.isNotEmpty && value.isNotEmpty) {
        dynamic parsedValue = num.tryParse(value) ?? value;
        parametrosIdeales[key] = parsedValue;
      }
    }

    final newConfig = HabitatConfig(
      tipoHabitat: tipoHabitatController.text,
      preferencias: preferenciasController.text,
      parametrosIdeales: parametrosIdeales,
      intervaloLimpieza: intervaloLimpieza,
    );

    await NotificationService().scheduleHabitatCleaningReminder(
      intervaloDias: newConfig.intervaloLimpieza,
      mascotaNombre: m.nombre,
      tipoHabitat: newConfig.tipoHabitat,
    );

    await FirestoreService().saveModuleHabitatConfig(
      m.familiaID,
      m.mascotaID,
      newConfig,
    );

    if (widget.isEditing) {
      widget.onSaved();
    }
  }
}
