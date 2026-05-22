import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/components/bottom_logo.dart';
import 'package:pawner_app/core/components/chat_bubble_clipper.dart';
import 'package:pawner_app/core/constants.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/screens/mascota/editar_mascota.dart';
import 'package:pawner_app/services/cloudinary_service.dart';
import 'package:pawner_app/services/firestore_service.dart';
import 'package:pawner_app/services/notification_service.dart';

class PetProfileScreen extends StatefulWidget {
  final Mascota mascota;

  const PetProfileScreen({super.key, required this.mascota});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late Mascota mascota = widget.mascota;

  String _getFormattedAgeString(DateTime birthDate) {
    final today = DateTime.now();
    int years = today.year - birthDate.year;
    int months = today.month - birthDate.month;
    int days = today.day - birthDate.day;

    if (days < 0) {
      months--;
      days = DateTime(today.year, today.month, 0).day + days;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    if (years > 0) {
      return "$years ${years == 1 ? 'año' : 'años'}";
    } else if (months > 0) {
      return "$months ${months == 1 ? 'mes' : 'meses'}";
    } else {
      return "${days == 0 ? 1 : days} ${days == 0 || days == 1 ? 'día' : 'días'}";
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Mascota>(
      stream: _firestoreService.streamMascota(
        widget.mascota.familiaID,
        widget.mascota.mascotaID,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Text(
                'Mascota no encontrada o eliminada',
                style: TextStyle(fontFamily: 'Nunito'),
              ),
            ),
          );
        }

        mascota = snapshot.data!;
        final String ageString = _getFormattedAgeString(
          mascota.fechaNacimiento,
        );

        return Scaffold(
          backgroundColor: AppColors.background, // Lavanda del dashboard
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                LucideIcons.chevronLeft,
                color: AppColors.textPrimary,
                size: 32,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(
                  LucideIcons.moreVertical,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
                onSelected: (value) async {
                  if (value == 'editar') {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            EditarMascotaScreen(mascota: mascota),
                      ),
                    );
                    if (result != null && result is Mascota) {
                      setState(() {
                        mascota = result;
                      });
                    }
                  } else if (value == 'eliminar') {
                    _confirmarEliminacion(context);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.pencil,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Editar mascota",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2, color: Colors.red, size: 20),
                        SizedBox(width: 10),
                        Text(
                          "Eliminar mascota",
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Contenido con Padding
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const SizedBox(height: 10),
                              // Perfil "Unido": Avatar grande y Container de nombre pegado
                              _buildJoinedProfileHeader(ageString, mascota),

                              if (mascota.especie.isNotEmpty &&
                                  mascota.raza.isNotEmpty &&
                                  !(mascota.especie == 'Otro' &&
                                      mascota.raza == 'Otro')) ...[
                                const SizedBox(height: 20),
                                _buildSpeciesBreedCard(mascota),
                              ],

                              const SizedBox(height: 40),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildQuickInfoItem(
                                    Icons.monitor_weight,
                                    "${mascota.peso} Kg",
                                    AppColors.secondary,
                                    onTap: () => _showWeightModal(context),
                                  ),
                                  _buildQuickInfoItem(
                                    mascota.genero == 'Macho'
                                        ? Icons.male
                                        : Icons.female,
                                    mascota.genero,
                                    mascota.genero == 'Macho'
                                        ? AppColors.male
                                        : AppColors.female,
                                  ),
                                  _buildQuickInfoItem(
                                    LucideIcons.scissors,
                                    mascota.esterilizado
                                        ? 'Esterilizado'
                                        : 'Sin Esterilizar',
                                    Colors.black,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                              _buildModulos(),
                              IconButton(
                                onPressed: () {
                                  _modulosDialog(context);
                                },
                                icon: const Icon(
                                  LucideIcons.plus,
                                  size: 22,
                                  fontWeight: .w600,
                                ),
                                style: TextButton.styleFrom(
                                  fixedSize: Size(50, 50),
                                  backgroundColor: AppColors.cardWhite
                                      .withAlpha(120),
                                  foregroundColor: AppColors.secondary,
                                  textStyle: const TextStyle(
                                    fontFamily: 'Nunito',
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: .circular(15),
                                    side: BorderSide(
                                      color: AppColors.cardWhite,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 45),
                              _buildObservationChip(
                                title: "Observaciones",
                                subtitle: mascota.observaciones.isEmpty
                                    ? "Añadir notas"
                                    : "Toca para ver notas",
                                icon: LucideIcons.stickyNote,
                                onTap: () => _showObservationsModal(context),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),

                        const Spacer(),

                        const BottomLogo(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _modulosDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors
          .transparent, // Para que se vea el borde redondeado del contenedor
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          List<String> allNames = AppModules.values
              .map((e) => AppModules.getName(e.name))
              .toList();

          List<String> availableModules = allNames
              .where((name) => !mascota.modulos.contains(name))
              .toList();

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, controller) => Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Gestionar Módulos",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Nunito',
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        _buildSectionTitle("Módulos Activos"),
                        if (mascota.modulos.isEmpty)
                          _buildEmptyState("No hay módulos activos")
                        else
                          ...mascota.modulos.map(
                            (modulo) => _buildModuleActionCard(
                              title: modulo,
                              icon: LucideIcons.x,
                              iconColor: Colors.redAccent,
                              onAction: () async {
                                setModalState(() {
                                  mascota.modulos.remove(modulo);
                                  if (modulo == "Hábitat") {
                                    NotificationService()
                                        .cancelHabitatReminder();
                                  }
                                });
                                await _firestoreService.actualizarMascota(
                                  mascota,
                                );
                                setState(() {});
                              },
                            ),
                          ),
                        const SizedBox(height: 20),
                        const Divider(thickness: 1, height: 1),
                        const SizedBox(height: 20),
                        _buildSectionTitle("Disponibles para añadir"),
                        if (availableModules.isEmpty)
                          _buildEmptyState("Has activado todos los módulos")
                        else
                          ...availableModules.map(
                            (modulo) => _buildModuleActionCard(
                              title: modulo,
                              icon: LucideIcons.plus,
                              iconColor: AppColors.secondary,
                              onAction: () async {
                                setModalState(
                                  () => mascota.modulos.add(modulo),
                                );
                                await _firestoreService.actualizarMascota(
                                  mascota,
                                );
                                setState(() {});
                              },
                            ),
                          ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS AUXILIARES PARA EL DIÁLOGO ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 5),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildModuleActionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onAction,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.withAlpha(25)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Nunito',
            color: AppColors.textPrimary,
          ),
        ),
        trailing: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withAlpha(25),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          onPressed: onAction,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
          fontFamily: 'Nunito',
        ),
      ),
    );
  }

  Widget _buildModulos() {
    if (mascota.modulos.isEmpty) {
      return Container(
        padding: .only(bottom: 20),
        height: 90,
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          mainAxisSize: .min,
          children: [
            Text(
              "No hay módulos activos\n¡Prueba a añadir uno!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.secondary,
                fontFamily: 'Nunito',
              ),
            ),
            Icon(LucideIcons.arrowDown, color: AppColors.secondary, size: 18),
          ],
        ),
      );
    } else {
      bool isRight = true;
      return Column(
        children: mascota.modulos.map((mod) {
          isRight = !isRight;
          log(mod);

          List<dynamic> info = AppModules.getModuleInfo(mod, mascota, context);

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildNavigationBubbleChip(
              title: info[0],
              subtitle: info[1],
              icon: info[2],
              isRight: isRight,
              onTap: () {
                final routeBuilder = info[3] as Route<dynamic> Function();
                Navigator.push(context, routeBuilder());
              },
            ),
          );
        }).toList(),
      );
    }
  }

  void _confirmarEliminacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Eliminar Mascota",
          style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold),
        ),
        content: Text(
          "¿Estás seguro de que quieres eliminar a ${mascota.nombre}? Esta acción no se puede deshacer.",
          style: const TextStyle(fontFamily: 'Nunito'),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () async {
              final familiaId = mascota.familiaID;
              final mascotaId = mascota.mascotaID;
              final nombreMascota = mascota.nombre;

              Navigator.pop(context); // Cierra el diálogo
              Navigator.pop(context);

              // Borrado en segundo plano
              final notifIds = await FirestoreService().eliminarMascota(
                familiaId,
                mascotaId,
              );

              final ns = NotificationService();
              for (final id in notifIds) {
                ns.cancel(id);
              }

              // SnackBar
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("$nombreMascota ha sido eliminado"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservationChip({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.secondary, // El mismo azul del título
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Nunito',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withAlpha(229),
                      fontFamily: 'Nunito',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }

  void _showWeightModal(BuildContext context) {
    double tempWeight = mascota.peso;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
          ),
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Actualizar Peso",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      LucideIcons.chevronDown,
                      size: 40,
                      color: AppColors.secondary,
                    ),
                    onPressed: () => setModalState(
                      () => tempWeight = (tempWeight - 0.1).clamp(0.1, 100.0),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      "${tempWeight.toStringAsFixed(1)} Kg",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      LucideIcons.chevronUp,
                      size: 40,
                      color: AppColors.secondary,
                    ),
                    onPressed: () => setModalState(
                      () => tempWeight = (tempWeight + 0.1).clamp(0.1, 100.0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final updatedMascota = Mascota(
                      mascotaID: mascota.mascotaID,
                      nombre: mascota.nombre,
                      especie: mascota.especie,
                      raza: mascota.raza,
                      chip: mascota.chip,
                      peso: double.parse(tempWeight.toStringAsFixed(1)),
                      fechaNacimiento: mascota.fechaNacimiento,
                      genero: mascota.genero,
                      esterilizado: mascota.esterilizado,
                      observaciones: mascota.observaciones,
                      fotoUrl: mascota.fotoUrl,
                      familiaID: mascota.familiaID,
                      modulos: mascota.modulos,
                    );
                    await FirestoreService().actualizarMascota(updatedMascota);
                    setState(() => mascota = updatedMascota);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    "Guardar",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showObservationsModal(BuildContext context) {
    final TextEditingController obsController = TextEditingController(
      text: mascota.observaciones,
    );
    bool isEditing = mascota.observaciones.isEmpty;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(76),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(38),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.stickyNote,
                        color: AppColors.complementary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        "Observaciones",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                    if (mascota.observaciones.isNotEmpty && !isEditing)
                      IconButton(
                        icon: const Icon(
                          LucideIcons.pencil,
                          color: AppColors.secondary,
                        ),
                        onPressed: () => setModalState(() => isEditing = true),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.background.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    controller: obsController,
                    enabled: isEditing,
                    maxLines: 5,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontFamily: 'Nunito',
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Escribe algo sobre tu mascota...",
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (isEditing) {
                        final updatedMascota = Mascota(
                          mascotaID: mascota.mascotaID,
                          nombre: mascota.nombre,
                          especie: mascota.especie,
                          raza: mascota.raza,
                          chip: mascota.chip,
                          peso: mascota.peso,
                          fechaNacimiento: mascota.fechaNacimiento,
                          genero: mascota.genero,
                          esterilizado: mascota.esterilizado,
                          observaciones: obsController.text.trim(),
                          fotoUrl: mascota.fotoUrl,
                          familiaID: mascota.familiaID,
                          modulos: mascota.modulos,
                        );
                        await FirestoreService().actualizarMascota(
                          updatedMascota,
                        );
                        setState(() => mascota = updatedMascota);
                        setModalState(() => isEditing = false);
                        if (mascota.observaciones.isEmpty && context.mounted) {
                          Navigator.pop(context);
                        }
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isEditing ? "Guardar" : "Cerrar",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      // Mostrar indicador de carga si es necesario, aunque aquí es directo
      try {
        final String? newUrl = await CloudinaryService().uploadImage(
          File(pickedFile.path),
        );
        if (newUrl != null) {
          final updatedMascota = Mascota(
            mascotaID: mascota.mascotaID,
            nombre: mascota.nombre,
            especie: mascota.especie,
            raza: mascota.raza,
            chip: mascota.chip,
            peso: mascota.peso,
            fechaNacimiento: mascota.fechaNacimiento,
            genero: mascota.genero,
            esterilizado: mascota.esterilizado,
            observaciones: mascota.observaciones,
            fotoUrl: newUrl,
            familiaID: mascota.familiaID,
            modulos: mascota.modulos,
          );
          await FirestoreService().actualizarMascota(updatedMascota);
          setState(() {
            mascota = updatedMascota;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error al subir la imagen")),
          );
        }
      }
    }
  }

  static const List<String> _petAvatarAssets = [
    'assets/images/fotos_perfil/buho.png',
    'assets/images/fotos_perfil/cheeta.png',
    'assets/images/fotos_perfil/ciervo.png',
    'assets/images/fotos_perfil/conejo.png',
    'assets/images/fotos_perfil/elefante.png',
    'assets/images/fotos_perfil/flamenco.png',
    'assets/images/fotos_perfil/jabali.png',
    'assets/images/fotos_perfil/jirafa.png',
    'assets/images/fotos_perfil/koala.png',
    'assets/images/fotos_perfil/lemur.png',
    'assets/images/fotos_perfil/lobo.png',
    'assets/images/fotos_perfil/mapache.png',
    'assets/images/fotos_perfil/nutria.png',
    'assets/images/fotos_perfil/oso.png',
    'assets/images/fotos_perfil/panda.png',
    'assets/images/fotos_perfil/tejon.png',
    'assets/images/fotos_perfil/tucan.png',
    'assets/images/fotos_perfil/zorro.png',
  ];

  void _showPhotoOptions() {
    final bool hasPhoto = mascota.fotoUrl.isNotEmpty;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPhoto) ...[
              ListTile(
                leading: const Icon(
                  LucideIcons.eye,
                  color: AppColors.secondary,
                ),
                title: const Text(
                  "Ver foto",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showFullScreenPhoto();
                },
              ),
              ListTile(
                leading: const Icon(
                  LucideIcons.image,
                  color: AppColors.secondary,
                ),
                title: const Text(
                  "Cambiar foto",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage();
                },
              ),
            ] else
              ListTile(
                leading: const Icon(
                  LucideIcons.upload,
                  color: AppColors.secondary,
                ),
                title: const Text(
                  "Subir foto",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage();
                },
              ),
            ListTile(
              leading: const Icon(
                LucideIcons.smile,
                color: AppColors.secondary,
              ),
              title: const Text(
                "Elegir avatar",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _showAvatarPicker();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.55,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Elige un avatar',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                ),
                itemCount: _petAvatarAssets.length,
                itemBuilder: (context, i) {
                  final asset = _petAvatarAssets[i];
                  final isSelected = mascota.fotoUrl == asset;
                  return GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      final updated = Mascota(
                        mascotaID: mascota.mascotaID,
                        nombre: mascota.nombre,
                        especie: mascota.especie,
                        raza: mascota.raza,
                        chip: mascota.chip,
                        peso: mascota.peso,
                        fechaNacimiento: mascota.fechaNacimiento,
                        genero: mascota.genero,
                        esterilizado: mascota.esterilizado,
                        observaciones: mascota.observaciones,
                        fotoUrl: asset,
                        familiaID: mascota.familiaID,
                        modulos: mascota.modulos,
                      );
                      await FirestoreService().actualizarMascota(updated);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.secondary
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.secondary.withAlpha(60),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipOval(
                        child: Image.asset(asset, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFullScreenPhoto() {
    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.black.withAlpha(204),
          child: Center(
            child: Hero(
              tag: 'pet_photo',
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  image: DecorationImage(
                    image: mascota.fotoUrl.isNotEmpty
                        ? (mascota.fotoUrl.startsWith('http')
                              ? NetworkImage(mascota.fotoUrl)
                              : AssetImage(mascota.fotoUrl) as ImageProvider)
                        : const AssetImage('assets/images/logo_grande_azul.png')
                              as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildJoinedProfileHeader(String ageString, Mascota mascota) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // Container del nombre (pegado al lateral y unido al avatar)
        Padding(
          padding: const EdgeInsets.only(left: 80),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              70,
              15,
              20,
              15,
            ), // Reducido padding vertical y ajustado el izquierdo
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mascota.nombre,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary, // Azul oscuro
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Row(
                      children: [
                        Text(
                          _formatDate(mascota.fechaNacimiento),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          "($ageString)",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (mascota.chip.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.fingerprint,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "Chip: \n${mascota.chip}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        // Avatar circular más grande
        GestureDetector(
          onTap: _showPhotoOptions,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Hero(
              tag: 'pet_photo',
              child: CircleAvatar(
                radius: 65,
                backgroundColor: Colors.white,
                backgroundImage: mascota.fotoUrl.isNotEmpty
                    ? (mascota.fotoUrl.startsWith('http')
                          ? NetworkImage(mascota.fotoUrl)
                          : AssetImage(mascota.fotoUrl) as ImageProvider)
                    : null,
                child: mascota.fotoUrl.isEmpty
                    ? const Icon(LucideIcons.dog, size: 60, color: Colors.grey)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeciesBreedCard(Mascota mascota) {
    // Si la raza es 'Otro', solo mostrar la especie
    final String displayInfo = (mascota.raza.toLowerCase() == 'otro')
        ? mascota.especie
        : "${mascota.especie} - ${mascota.raza}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.pets, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Especie y Raza",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
                  ),
                ),
                Text(
                  displayInfo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoItem(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBubbleChip({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isRight,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: PhysicalShape(
        clipper: ChatBubbleClipper(isRight: isRight),
        color: AppColors.homeScreenOrange,
        elevation: 4,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.homeScreenOrange, size: 24),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withAlpha(229),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: Colors.white,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
