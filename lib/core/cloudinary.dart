import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../app_config.dart';

class UploadedImage {
  final String publicId;
  final int width, height, bytes;
  final String format;
  UploadedImage({
    required this.publicId,
    required this.width,
    required this.height,
    required this.bytes,
    required this.format,
  });
}

/// Cloudinary Unsigned 업로드 + URL 조립.
/// Firestore 에는 publicId 만 저장하고, 필요한 크기는 URL 옵션으로 그때그때 만듭니다.
class Cloudinary {
  Cloudinary._();

  static String _url(String publicId, String options) {
    final cloud = AppConfig.cloudinaryCloudName;
    if (options.isEmpty) {
      return 'https://res.cloudinary.com/$cloud/image/upload/$publicId';
    }
    return 'https://res.cloudinary.com/$cloud/image/upload/$options/$publicId';
  }

  /// 앨범 그리드 썸네일 (~30KB)
  static String thumb(String publicId, {int size = 400}) =>
      _url(publicId, 'w_$size,h_$size,c_fill,f_auto,q_auto');

  /// 크게 보기 (~200KB)
  static String large(String publicId, {int width = 1600}) =>
      _url(publicId, 'w_$width,c_limit,f_auto,q_auto:good');

  /// 원본 그대로 (다운로드용)
  static String original(String publicId) => _url(publicId, '');

  /// 브라우저에서 바로 저장되도록 하는 다운로드 URL
  static String download(String publicId) {
    final cloud = AppConfig.cloudinaryCloudName;
    return 'https://res.cloudinary.com/$cloud/image/upload/fl_attachment/$publicId';
  }

  static Future<UploadedImage> upload(
    Uint8List bytes,
    String filename, {
    bool keepOriginal = false,
  }) async {
    if (!AppConfig.isCloudinaryConfigured) {
      throw Exception('Cloudinary 설정이 비어 있습니다. lib/app_config.dart 를 확인해주세요.');
    }
    final preset = (keepOriginal && AppConfig.cloudinaryOriginalPreset.isNotEmpty)
        ? AppConfig.cloudinaryOriginalPreset
        : AppConfig.cloudinaryUploadPreset;

    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload');
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) {
      String msg = res.body;
      try {
        msg = (jsonDecode(res.body)['error']?['message'] ?? res.body).toString();
      } catch (_) {}
      throw Exception('업로드 실패 (${res.statusCode}): $msg');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return UploadedImage(
      publicId: j['public_id'] as String,
      width: (j['width'] ?? 0) as int,
      height: (j['height'] ?? 0) as int,
      bytes: (j['bytes'] ?? 0) as int,
      format: (j['format'] ?? '') as String,
    );
  }
}
