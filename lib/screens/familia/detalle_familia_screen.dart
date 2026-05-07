import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/app_colors.dart';
import 'package:pawner_app/core/model/familia.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/core/model/usuario.dart';
import 'package:pawner_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pawner_app/screens/familia/elegir_familia.dart';
import 'package:pawner_app/screens/mascota/detalle_mascota.dart';
import 'package:pawner_app/core/constants.dart';
import 'package:share_plus/share_plus.dart';

import 'package:pawner_app/screens/mascota/editar_mascota.dart';

class DetalleFamiliaScreen extends StatefulWidget {
  final String familiaID;

  const DetalleFamiliaScreen({super.key, required this.familiaID});

  @override
  State<DetalleFamiliaScreen> createState() => _DetalleFamiliaScreenState();
}

class _DetalleFamiliaScreenState extends State<DetalleFamiliaScreen> {
  final FirestoreService _fs = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isCopied = false;

  Future<void> _salirDeFamilia() async {
    if (_currentUser == null) return;

    Usuario usuario = await _fs.getCurrentUser(_currentUser!);

    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la familia?'),
        content: Text(
          usuario.rol == UserRol.admin
              ? 'Eres el administrador. Si sales y no hay más miembros, la familia se eliminará permanentemente. Si hay más miembros, uno será nombrado administrador.'
              : 'Dejarás de tener acceso a los datos de esta familia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.dark),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _fs.abandonarFamilia(usuario);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ElegirFamiliaLayout()),
          (route) => false,
        );
      }
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado'),
        backgroundColor: AppColors.secondary,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _regenerarCodigo() async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Regenerar código?'),
        content: const Text(
          'El código actual dejará de funcionar para nuevos miembros. ¿Estás seguro?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Regenerar',
              style: TextStyle(color: AppColors.complementary),
            ),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _fs.regenerarCodigoFamilia(widget.familiaID);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código regenerado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.dark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _salirDeFamilia,
            child: const Text(
              'Salir de la familia',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: FutureBuilder<Usuario>(
        future: _fs.getCurrentUser(_currentUser!),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final usuarioActual = userSnapshot.data!;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Familias')
                .doc(widget.familiaID)
                .snapshots(),
            builder: (context, familySnapshot) {
              if (familySnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!familySnapshot.hasData || !familySnapshot.data!.exists) {
                return const Center(child: Text("No se encontró la familia"));
              }

              final familiaData =
                  familySnapshot.data!.data() as Map<String, dynamic>;
              final familia = Familia.fromJson(
                familiaData,
                familySnapshot.data!.id,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      familia.nombre,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInvitationCodeCard(familia, usuarioActual),
                    const SizedBox(height: 30),
                    const Text(
                      'Nuestras Mascotas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildMascotasGrid(),
                    const SizedBox(height: 40),
                    const Text(
                      'Integrantes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.dark,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildIntegrantesList(usuarioActual),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInvitationCodeCard(Familia familia, Usuario usuario) {
    bool isAdmin = usuario.rol == UserRol.admin;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Código de Invitación',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                  fontFamily: 'Nunito',
                ),
              ),
              if (isAdmin)
                IconButton(
                  onPressed: _regenerarCodigo,
                  icon: const Icon(
                    LucideIcons.refreshCw,
                    size: 18,
                    color: AppColors.complementary,
                  ),
                  tooltip: 'Regenerar código',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    familia.codigoInvitacion,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.secondary,
                      fontFamily: 'Nunito',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: _isCopied ? Icons.check : LucideIcons.copy,
                color: _isCopied ? Colors.green : AppColors.secondary,
                onTap: () => _copyToClipboard(familia.codigoInvitacion),
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                icon: LucideIcons.share2,
                color: AppColors.secondary,
                onTap: () {
                  final String message =
                      '¡Únete a mi familia en Pawner! Usa este código para ver a nuestras mascotas: ${familia.codigoInvitacion}';
                  Share.share(message);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  void _showPetOptionsMenu(Mascota mascota, Offset position) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        position & const Size(40, 40), // Tap position
        Offset.zero & overlay.size,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      items: [
        const PopupMenuItem(
          value: 'editar',
          child: Row(
            children: [
              Icon(LucideIcons.pencil, color: AppColors.secondary, size: 20),
              SizedBox(width: 10),
              Text("Editar mascota", style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'eliminar',
          child: Row(
            children: [
              Icon(LucideIcons.trash2, color: Colors.red, size: 20),
              SizedBox(width: 10),
              Text("Eliminar mascota",
                  style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == 'editar') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EditarMascotaScreen(mascota: mascota)),
        );
      } else if (value == 'eliminar') {
        _confirmarEliminacion(context, mascota);
      }
    });
  }

  void _confirmarEliminacion(BuildContext context, Mascota mascota) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Eliminar Mascota", style: TextStyle(fontFamily: 'Nunito', fontWeight: FontWeight.bold)),
        content: Text("¿Estás seguro de que quieres eliminar a ${mascota.nombre}? Esta acción no se puede deshacer.",
            style: const TextStyle(fontFamily: 'Nunito')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo
              await _fs.eliminarMascota(mascota.familiaID, mascota.mascotaID);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${mascota.nombre} ha sido eliminado"), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildMascotasGrid() {
    return StreamBuilder<List<Mascota>>(
      stream: _fs.streamMascotas(widget.familiaID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Aún no hay mascotas en esta familia.",
              textAlign: TextAlign.center,
            ),
          );
        }

        final mascotas = snapshot.data!;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.85,
          ),
          itemCount: mascotas.length,
          itemBuilder: (context, index) {
            final mascota = mascotas[index];
            Offset? tapPosition;

            return GestureDetector(
              onTapDown: (details) => tapPosition = details.globalPosition,
              onLongPress: () {
                if (tapPosition != null) {
                  _showPetOptionsMenu(mascota, tapPosition!);
                }
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PetProfileScreen(mascota: mascota),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.lightSecondary,
                      backgroundImage: mascota.fotoUrl.isNotEmpty
                          ? (mascota.fotoUrl.contains('assets')
                                ? AssetImage(mascota.fotoUrl) as ImageProvider
                                : NetworkImage(mascota.fotoUrl))
                          : null,
                      child: mascota.fotoUrl.isEmpty
                          ? const Icon(
                              Icons.pets,
                              color: AppColors.secondary,
                              size: 30,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      mascota.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.secondary,
                      ),
                    ),
                   /* Text(
                      mascota.genero,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),*/
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmarEliminarMiembro(Usuario miembro) async {
    bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar miembro?'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${miembro.nombre} de la familia?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.dark),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _fs.eliminarMiembroFamilia(miembro.usuarioID);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${miembro.nombre} ha sido eliminado de la familia'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildIntegrantesList(Usuario usuarioActual) {
    return StreamBuilder<List<Usuario>>(
      stream: _fs.streamMiembros(widget.familiaID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text("No hay integrantes registrados.");
        }

        final miembros = snapshot.data!;

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: miembros.length,
            itemBuilder: (context, index) {
              final miembro = miembros[index];
              final bool isAdmin = usuarioActual.rol == UserRol.admin;
              final bool isNotMe = miembro.usuarioID != usuarioActual.usuarioID;

              return GestureDetector(
                onTap: (isAdmin && isNotMe)
                    ? () => _confirmarEliminarMiembro(miembro)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.accent,
                        backgroundImage: miembro.fotoUrl.isNotEmpty
                            ? (miembro.fotoUrl.contains('assets') ||
                                      !miembro.fotoUrl.startsWith('http')
                                  ? AssetImage(
                                          "assets/images/fotos_perfil/${miembro.fotoUrl}.png",
                                        )
                                        as ImageProvider
                                  : NetworkImage(miembro.fotoUrl))
                            : null,
                        child: miembro.fotoUrl.isEmpty
                            ? const Icon(LucideIcons.user, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        miembro.nombre,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
