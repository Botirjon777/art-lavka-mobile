import 'dart:typed_data';

import '../utils/error_mapper.dart';
import '../utils/json.dart';
import '../utils/result.dart';
import 'api_client.dart';

/// Storage bucket names (SPEC §5). Keep in one place so paths never drift.
abstract final class Buckets {
  static const printFiles = 'print-files'; // private
  static const printPreviews = 'print-previews'; // public
  static const mockups = 'mockups'; // public
  static const productTemplates = 'product-templates'; // public
  static const signatures = 'signatures'; // private
}

/// A presigned upload target from the API.
class UploadTarget {
  const UploadTarget({
    required this.uploadUrl,
    required this.bucket,
    required this.path,
    this.publicUrl,
  });

  final String uploadUrl;
  final String bucket;
  final String path;
  final String? publicUrl;

  factory UploadTarget.fromJson(Map<String, dynamic> json) => UploadTarget(
    uploadUrl: json['upload_url'] as String,
    bucket: json['bucket'] as String,
    path: json['path'] as String,
    publicUrl: Json.stringOrNull(json['public_url']),
  );
}

/// Uploads via presigned URLs (BACKEND_NODE.md §5). The client asks the API for
/// a presigned PUT, uploads the bytes directly to storage, then references the
/// returned [UploadTarget.path]. Private print files are only readable via a
/// server-issued signed URL for production/admin (SPEC §13).
class StorageService {
  StorageService(this._api);
  final ApiClient _api;

  /// Ask the API for a presigned upload target for [bucket].
  Future<Result<UploadTarget>> presignUpload({
    required String bucket,
    required String contentType,
  }) => ErrorMapper.guard(() async {
    final data =
        await _api.post(
              '/storage/presign-upload',
              data: {'bucket': bucket, 'contentType': contentType},
            )
            as Map;
    return UploadTarget.fromJson(data.cast<String, dynamic>());
  });

  /// Presign + upload [bytes] in one step; returns the stored path.
  Future<Result<String>> uploadBytes({
    required String bucket,
    required Uint8List bytes,
    required String contentType,
  }) => ErrorMapper.guard(() async {
    final data =
        await _api.post(
              '/storage/presign-upload',
              data: {'bucket': bucket, 'contentType': contentType},
            )
            as Map;
    final target = UploadTarget.fromJson(data.cast<String, dynamic>());
    await _api.putBinary(target.uploadUrl, bytes, contentType: contentType);
    return target.path;
  });

  /// A short-lived signed URL for a design's private print file (ops/admin only).
  Future<Result<String>> printFileUrl(String designId) =>
      ErrorMapper.guard(() async {
        final data = await _api.get('/storage/print-file/$designId') as Map;
        return data['url'] as String;
      });
}
