import 'dart:io';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudinaryService {
  final String cloudName = dotenv.get('CLOUDINARY_CLOUD_NAME', fallback: '');
  final String uploadPreset = dotenv.get(
    'CLOUDINARY_UPLOAD_PRESET',
    fallback: 'ml_default',
  );

  Future<String?> uploadImage(File imageFile) async {
    if (cloudName.isEmpty) {
      log("Error: CLOUDINARY_CLOUD_NAME no configurado en .env");
      return null;
    }

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        final jsonMap = jsonDecode(responseString);
        return jsonMap['secure_url'];
      } else {
        log("Error al subir a Cloudinary: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      log("Excepción al subir imagen: $e");
      return null;
    }
  }
}
