import 'package:dio/dio.dart';

class CatboxUploader {
  CatboxUploader({Dio? client})
      : _dio = client ??
            Dio(
              BaseOptions(
                baseUrl: 'https://catbox.moe',
                headers: const {
                  'Accept': 'text/plain',
                },
                  connectTimeout: const Duration(seconds: 30),
                  receiveTimeout: const Duration(seconds: 30),
              ),
            );

  final Dio _dio;

  Future<String> uploadFile(
    String path, {
    required String filename,
    void Function(int sent, int total)? onProgress,
  }) async {
    final formData = FormData.fromMap({
      'reqtype': 'fileupload',
      'fileToUpload': await MultipartFile.fromFile(path, filename: filename),
    });

    final response = await _dio.post(
      '/user/api.php',
      data: formData,
      onSendProgress: onProgress,
    );
    if (response.statusCode == 200 && response.data is String) {
      final url = (response.data as String).trim();
      if (url.startsWith('http')) {
        return url;
      }
      throw Exception('Catbox error: $url');
    }
    throw Exception(
        'Catbox upload failed (${response.statusCode}): ${response.data}');
  }
}

