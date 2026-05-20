import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/modulo_habitat/modulo_habitat_config.dart';
import 'package:pawner_app/screens/modulos/habitat/config_habitat_screen.dart';
import 'package:pawner_app/services/firestore_service.dart';

class HabitatScreen extends StatefulWidget {
  final Mascota m;
  const HabitatScreen({super.key, required this.m});

  @override
  State<HabitatScreen> createState() => _HabitatScreenState();
}

class _HabitatScreenState extends State<HabitatScreen> {
  bool isEditing = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HabitatConfig?>(
      stream: FirestoreService().getHabitatConfig(
        widget.m.familiaID,
        widget.m.mascotaID,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _cargando();
        }
        final config = snapshot.data;

        return Scaffold(
          backgroundColor: AppColors.homeScreenBackground,
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
              "Hábitat de ${widget.m.nombre}",
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 18,
              ),
            ),
          ),
          body: config == null || isEditing
              ? ConfigHabitatScreen(
                  mascota: widget.m,
                  config: config,
                  isEditing: isEditing,
                  onSaved: () {
                    setState(() => isEditing = false);
                  },
                )
              : _buildHabitatInfo(config),
        );
      },
    );
  }

  Widget _buildHabitatInfo(HabitatConfig config) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------ TARJETA PRINCIPAL: TIPO DE HÁBITAT & LIMPIEZA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.home,
                  color: AppColors.homeScreenOrange,
                  size: 50,
                ),
                const SizedBox(height: 12),
                Text(
                  config.tipoHabitat.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 15),
                const Divider(height: 1),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.sparkles,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Limpieza cada: ${config.intervaloLimpieza} días",
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // ------ SECCIÓN: PARÁMETROS IDEALES
          if (config.parametrosIdeales.isNotEmpty) ...[
            const Text(
              "Parámetros ideales",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 13,
                mainAxisSpacing: 10,
                childAspectRatio: 2,
              ),
              itemCount: config.parametrosIdeales.length,
              itemBuilder: (context, index) {
                String key = config.parametrosIdeales.keys.elementAt(index);
                String value = config.parametrosIdeales[key].toString();

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground.withAlpha(100),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        key,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 25),
          ],

          // ------ SECCIÓN: PREFERENCIAS ADICIONALES
          if (config.preferencias.trim().isNotEmpty) ...[
            const Text(
              "Preferencias adicionales",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.inputBackground, width: 1),
              ),
              child: Text(
                config.preferencias,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 35),
          ],

          // ------ BOTÓN DE EDICIÓN
          SizedBox(
            width: double.infinity,
            height: 55,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => isEditing = true),
              icon: const Icon(LucideIcons.edit2, size: 18),
              label: const Text(
                "EDITAR CONFIGURACIÓN",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cargando() {
    return const Center(child: CircularProgressIndicator());
  }
}
