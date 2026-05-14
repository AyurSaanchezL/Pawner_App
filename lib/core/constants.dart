import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pawner_app/core/model/mascota.dart';
import 'package:pawner_app/screens/modulos/comida/dashboard_comida_screen.dart';
import 'package:pawner_app/screens/modulos/paseo/paseo_screen.dart';
import 'package:pawner_app/screens/modulos/veterinario/veterinario_screen.dart';

class Constants {
  static final TextStyle inputStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Nunito',
  );

  static const Map<String, List<String>> especiesYRazas = {
    'Perro': [
      'Labrador Retriever',
      'Golden Retriever',
      'Pastor Alemán',
      'Bulldog Francés',
      'Bulldog Inglés',
      'Caniche (Poodle)',
      'Chihuahua',
      'Beagle',
      'Boxer',
      'Dachshund (Teckel)',
      'Siberian Husky',
      'Pug (Carlino)',
      'Cocker Spaniel',
      'Rottweiler',
      'Yorkshire Terrier',
      'Shih Tzu',
      'Border Collie',
      'Galgo',
      'Mastín',
      'Bodeguero',
      'Mestizo / Otro',
    ],
    'Gato': [
      'Persa',
      'Siamés',
      'Maine Coon',
      'Bengalí',
      'Sphynx (Esfinge)',
      'Común Europeo',
      'Ragdoll',
      'British Shorthair',
      'Bosque de Noruega',
      'Azul Ruso',
      'Angora',
      'Mestizo / Otro',
    ],
    'Hámster': [
      'Sirio (Dorado)',
      'Ruso',
      'Roborowski',
      'Chino',
      'Campbell',
      'Otro',
    ],
    'Pájaro': [
      'Canario',
      'Periquito',
      'Agapornis (Inseparables)',
      'Loro',
      'Cacatúa',
      'Ninfa (Carolina)',
      'Diamante de Gould',
      'Jilguero',
      'Otro',
    ],
    'Pez': [
      'Betta',
      'Goldfish',
      'Guppy',
      'Tetra Neón',
      'Pez Ángel (Escalar)',
      'Molly',
      'Platy',
      'Corydora',
      'Pez Disco',
      'Oscar',
      'Otro',
    ],
    'Conejo': [
      'Belier (Orejas caídas)',
      'Enano / Toy',
      'Angora',
      'Cabeza de León',
      'Gigante de Flandes',
      'Holandés',
      'Otro',
    ],
    'Cobaya': [
      'Americana (Pelo corto)',
      'Abisinia (Remolinos)',
      'Peruana (Pelo largo)',
      'Rex',
      'Skinny (Sin pelo)',
      'Otro',
    ],
    'Hurón': [
      'Sable',
      'Albino',
      'Champagne',
      'Silver / Plateado',
      'Panda',
      'Otro',
    ],
    'Reptil': [
      'Tortuga de agua',
      'Tortuga de tierra',
      'Gecko Leopardo',
      'Dragón Barbudo',
      'Iguana Verde',
      'Serpiente del Maíz',
      'Pitón Real',
      'Otro',
    ],
    'Anfibio': [
      'Axolote',
      'Rana Albina (Xenopus)',
      'Rana de ojos rojos',
      'Tritón',
      'Sapo de vientre de fuego',
      'Otro',
    ],
    'Erizo': ['Erizo de tierra africano', 'Erizo orejudo', 'Otro'],
    'Chinchilla': [
      'Standard (Gris)',
      'Blanca',
      'Beige',
      'Terciopelo negro',
      'Otro',
    ],
    'Otro': ['Otro'],
  };
}

enum AppModules {
  paseo,
  veterinario,
  comida;

  static String getName(String mod) {
    switch (mod) {
      case 'paseos':
        return 'Paseos';
      case 'veterinario':
        return 'Veterinario';
      case 'comida':
        return 'Comida';
      default:
        return mod;
    }
  }

  static List<dynamic> getModuleInfo(
    String modulo,
    Mascota mascota,
    BuildContext context,
  ) {
    switch (modulo) {
      case 'Veterinario':
        return [
          'Veterinario',
          'Cuidados y vacunas',
          LucideIcons.stethoscope,
          MaterialPageRoute(
            builder: (context) => VeterinarioScreen(mascota: mascota),
          ),
        ];
      case 'Paseos':
        return [
          'Paseos',
          'Bienestar y salud',
          const IconData(0xe4a1, fontFamily: 'MaterialIcons'),
          MaterialPageRoute(builder: (context) => PaseoScreen(m: mascota)),
        ];
      case 'Comida':
        return [
          'Comida',
          'Alimentación y dieta',
          LucideIcons.utensils,
          MaterialPageRoute(
            builder: (context) => DashboardComidaScreen(mascota: mascota),
          ),
        ];
      default:
        return ['Desconocido', '', ''];
    }
  }
}

enum UserRol { admin, miembro }

enum FotosPerfil {
  zorro('assets/images/fotos_perfil/zorro.png'),
  lemur('assets/images/fotos_perfil/lemur.png'),
  jabali('assets/images/fotos_perfil/jabali.png'),
  tucan('assets/images/fotos_perfil/tucan.png'),
  tejon('assets/images/fotos_perfil/tejon.png'),
  flamenco('assets/images/fotos_perfil/flamenco.png'),
  elefante('assets/images/fotos_perfil/elefante.png'),
  panda('assets/images/fotos_perfil/panda.png'),
  oso('assets/images/fotos_perfil/oso.png'),
  ciervo('assets/images/fotos_perfil/ciervo.png'),
  nutria('assets/images/fotos_perfil/nutria.png'),
  cheeta('assets/images/fotos_perfil/cheeta.png'),
  mapache('assets/images/fotos_perfil/mapache.png'),
  buho('assets/images/fotos_perfil/buho.png'),
  lobo('assets/images/fotos_perfil/lobo.png'),
  jirafa('assets/images/fotos_perfil/jirafa.png'),
  koala('assets/images/fotos_perfil/koala.png');

  final String path;
  const FotosPerfil(this.path);

  static String fromPath(String path) {
    String name = path.split('/').last;

    return FotosPerfil.values
        .firstWhere(
          (e) => e.name == name.substring(0, name.indexOf('.')),
          orElse: () => FotosPerfil.zorro, // Valor por defecto
        )
        .name;
  }

  static String getProfileImage(String image) {
    String path = "";
    for (FotosPerfil f in FotosPerfil.values) {
      if (image == f.name) {
        path = f.path;
      }
    }

    return path;
  }
}
