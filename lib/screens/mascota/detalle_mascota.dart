import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/components/bottom_logo.dart';
import 'package:pawner_app/core/components/chat_bubble_clipper.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/screens/mascota/editar_mascota.dart';
import 'package:pawner_app/screens/modulos/comida/comida_screen.dart';
import 'package:pawner_app/screens/modulos/veterinario/veterinario_screen.dart';
import 'package:pawner_app/services/cloudinary_service.dart';
import 'package:pawner_app/services/firestore_service.dart';

class PetProfileScreen extends StatefulWidget {
  final Mascota mascota;

  const PetProfileScreen({super.key, required this.mascota});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  late Mascota mascota;

  @override
  void initState() {
    super.initState();
    mascota = widget.mascota;
  }

  String _getFormattedAgeString(DateTime birthDate) {
    final today = DateTime.now();
    int years = today.year - birthDate.year;
    int months = today.month - birthDate.month;
    int days = today.day - birthDate.day;

    // Adjust for negative days (borrow from months)
    if (days < 0) {
      months--;
      // Calculate days in the previous month
      days = DateTime(today.year, today.month, 0).day + days;
    }
    // Adjust for negative months (borrow from years)
    if (months < 0) {
      years--;
      months += 12;
    }

    if (years > 0) {
      return "$years ${years == 1 ? 'año' : 'años'}";
    } else if (months > 0) {
      return "$months ${months == 1 ? 'mes' : 'meses'}";
    } else {
      // Ensure at least 1 day is shown if difference is 0 days
      return "${days == 0 ? 1 : days} ${days == 0 || days == 1 ? 'día' : 'días'}";
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final String ageString = _getFormattedAgeString(mascota.fechaNacimiento);

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
                    builder: (context) => EditarMascotaScreen(mascota: mascota),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          // Perfil "Unido": Avatar grande y Container de nombre pegado
                          _buildJoinedProfileHeader(ageString),

                          if (mascota.especie.isNotEmpty &&
                              mascota.raza.isNotEmpty &&
                              !(mascota.especie == 'Otro' &&
                                  mascota.raza == 'Otro')) ...[
                            const SizedBox(height: 20),
                            _buildSpeciesBreedCard(),
                          ],

                          const SizedBox(height: 40),

                          // Fila de Info Rápida con iconos del formulario
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
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

                          // Chips de navegación usando ChatBubbleClipper
                          _buildNavigationBubbleChip(
                            title: "Comida",
                            subtitle: "Dieta y horarios",
                            icon: LucideIcons.utensils,
                            isRight: false,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ComidaScreen(mascota: mascota),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildNavigationBubbleChip(
                            title: "Veterinario",
                            subtitle: "Cuidados y vacunas",
                            icon: LucideIcons.stethoscope,
                            isRight: true,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VeterinarioScreen(mascota: mascota),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildObservationChip(
                            title: "Observaciones",
                            subtitle: mascota.observaciones.isEmpty
                                ? "Añadir notas"
                                : "Toca para ver notas",
                            icon: LucideIcons.stickyNote,
                            onTap: () => _showObservationsModal(context),
  ),
                          const SizedBox(height: 20), // Added spacing before footer
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Footer (IGUAL al de perfil_screen, pegado al final y extremos)
                    const BottomLogo(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              Navigator.pop(context); // Cerrar diálogo
              await FirestoreService().eliminarMascota(
                mascota.familiaID,
                mascota.mascotaID,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${mascota.nombre} ha sido eliminado"),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context); // Volver a la pantalla anterior
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
          borderRadius: BorderRadius.circular(20),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                    );
                    await FirestoreService().actualizarMascota(updatedMascota);
                    setState(() => mascota = updatedMascota);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                      borderRadius: BorderRadius.circular(2),
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
                        borderRadius: BorderRadius.circular(20),
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

  void _showPhotoOptions() {
    final bool hasPhoto = mascota.fotoUrl.isNotEmpty;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            const SizedBox(height: 10),
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

  Widget _buildJoinedProfileHeader(String ageString) {
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
              borderRadius: BorderRadius.circular(30),
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
                    Text(
                      "${_formatDate(mascota.fechaNacimiento)} ($ageString)",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
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
                        "Chip: ${mascota.chip}",
                        style: const TextStyle(
                          fontSize: 13,
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

  Widget _buildSpeciesBreedCard() {
    // Si la raza es 'Otro', solo mostrar la especie
    final String displayInfo = (mascota.raza.toLowerCase() == 'otro')
        ? mascota.especie
        : "${mascota.especie} - ${mascota.raza}";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(20),
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
