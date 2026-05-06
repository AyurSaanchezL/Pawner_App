import 'package:flutter/material.dart';

class Constants {
  static final TextStyle inputStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
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
      'Mestizo / Otro'
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
      'Mestizo / Otro'
    ],
    'Hámster': [
      'Sirio (Dorado)',
      'Ruso',
      'Roborowski',
      'Chino',
      'Campbell',
      'Otro'
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
      'Otro'
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
      'Otro'
    ],
    'Conejo': [
      'Belier (Orejas caídas)',
      'Enano / Toy',
      'Angora',
      'Cabeza de León',
      'Gigante de Flandes',
      'Holandés',
      'Otro'
    ],
    'Cobaya': [
      'Americana (Pelo corto)',
      'Abisinia (Remolinos)',
      'Peruana (Pelo largo)',
      'Rex',
      'Skinny (Sin pelo)',
      'Otro'
    ],
    'Hurón': [
      'Sable',
      'Albino',
      'Champagne',
      'Silver / Plateado',
      'Panda',
      'Otro'
    ],
    'Reptil': [
      'Tortuga de agua',
      'Tortuga de tierra',
      'Gecko Leopardo',
      'Dragón Barbudo',
      'Iguana Verde',
      'Serpiente del Maíz',
      'Pitón Real',
      'Otro'
    ],
    'Anfibio': [
      'Axolote',
      'Rana Albina (Xenopus)',
      'Rana de ojos rojos',
      'Tritón',
      'Sapo de vientre de fuego',
      'Otro'
    ],
    'Erizo': [
      'Erizo de tierra africano',
      'Erizo orejudo',
      'Otro'
    ],
    'Chinchilla': [
      'Standard (Gris)',
      'Blanca',
      'Beige',
      'Terciopelo negro',
      'Otro'
    ],
    'Otro': ['Otro'],
  };
}

enum UserRol { admin, miembro }
