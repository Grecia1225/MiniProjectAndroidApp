import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Uploads an image to Cloudinary using an UNSIGNED upload preset — safe to
/// ship inside a client app, since an unsigned preset can only upload new
/// images, never delete, list, or manage anything else in your account.
///
/// Returns the public HTTPS URL of the uploaded image, or null if the
/// upload failed (network issue, wrong cloud name/preset, etc).
///
/// ── One-time setup (in the Cloudinary dashboard) ──────────────────────────
/// 1. Sign up free at https://cloudinary.com (no card required).
/// 2. On the dashboard home page, copy your "Cloud name".
/// 3. Go to Settings (gear icon) → Upload → scroll to "Upload presets" →
///    "Add upload preset".
/// 4. Set "Signing Mode" to "Unsigned", save, and copy the preset name
///    Cloudinary generates (or set your own).
/// 5. Paste both values into [cloudName] and [uploadPreset] below.
class CloudinaryUploader {
  // TODO: replace these two with your own values from the Cloudinary
  // dashboard (see setup steps above). The app will not be able to upload
  // any images until these are filled in.
  static const String cloudName    = 'djcuje59h';
  static const String uploadPreset = 'mtc_upload';

  /// [folder] groups uploads inside your Cloudinary media library, e.g.
  /// 'secondhand', 'listings', 'chat' — purely organizational, optional.
  static Future<String?> uploadImage(File file, {String folder = 'mtc'}) async {
    try {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse =
      await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['secure_url'] as String?;
      }
      // Non-200 usually means wrong cloud name/preset, or the preset isn't
      // set to "Unsigned" — check the Cloudinary dashboard settings above.
      // ignore: avoid_print
      print('Cloudinary upload failed: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Cloudinary upload exception: $e');
      return null;
    }
  }
}