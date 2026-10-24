import 'dart:typed_data';

abstract interface class StorageService {
  Future<Uri> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });
}
