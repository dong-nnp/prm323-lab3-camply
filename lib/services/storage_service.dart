import 'dart:typed_data';

abstract interface class StorageService {
  Future<Uri> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    void Function(double progress)? onProgress,
  });

  Future<Uint8List> readBytes({
    required String path,
    int maxSizeBytes = 5 * 1024 * 1024,
  });
}
