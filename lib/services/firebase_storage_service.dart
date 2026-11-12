import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../core/errors/app_exception.dart';
import 'storage_service.dart';

/// Firebase Cloud Storage adapter for authenticated owner reports.
final class FirebaseStorageService implements StorageService {
  FirebaseStorageService(this.ready);

  static const maxUploadBytes = 5 * 1024 * 1024;
  final Future<void> Function() ready;

  @override
  Future<Uri> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
    void Function(double progress)? onProgress,
  }) async {
    if (path.trim().isEmpty || bytes.isEmpty || bytes.length > maxUploadBytes) {
      throw const AppException(
        code: 'report_failed',
        message: 'Báo cáo không hợp lệ hoặc vượt quá giới hạn 5 MB.',
      );
    }
    await ready();
    final ref = FirebaseStorage.instance.ref(path);
    final task = ref.putData(bytes, SettableMetadata(contentType: contentType));
    StreamSubscription<TaskSnapshot>? subscription;
    try {
      subscription = task.snapshotEvents.listen((snapshot) {
        final total = snapshot.totalBytes;
        if (total > 0) {
          onProgress?.call((snapshot.bytesTransferred / total).clamp(0.0, 1.0));
        } else if (snapshot.state == TaskState.success) {
          onProgress?.call(1.0);
        }
      }, onError: (_) {});
      final done = await task;
      onProgress?.call(1.0);
      return Uri(
        scheme: 'gs',
        host: done.ref.bucket,
        path: '/${done.ref.fullPath}',
      );
    } on FirebaseException catch (error) {
      throw _mapStorageException(error);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        code: 'report_failed',
        message: 'Không thể tải báo cáo lên Cloud Storage. Vui lòng thử lại.',
      );
    } finally {
      await subscription?.cancel();
    }
  }

  @override
  Future<Uint8List> readBytes({
    required String path,
    int maxSizeBytes = maxUploadBytes,
  }) async {
    if (path.trim().isEmpty) {
      throw const AppException(
        code: 'report_failed',
        message: 'Đường dẫn tệp báo cáo không hợp lệ.',
      );
    }
    await ready();
    try {
      final data = await FirebaseStorage.instance
          .ref(path)
          .getData(maxSizeBytes);
      if (data == null) {
        throw const AppException(
          code: 'report_failed',
          message: 'Không đọc được nội dung báo cáo đã tải lên.',
        );
      }
      return data;
    } on FirebaseException catch (error) {
      throw _mapStorageException(error);
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        code: 'report_failed',
        message: 'Không đọc được nội dung báo cáo đã tải lên.',
      );
    }
  }

  AppException _mapStorageException(
    FirebaseException error,
  ) => switch (error.code) {
    'unauthenticated' => const AppException(
      code: 'unauthenticated',
      message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    ),
    'unauthorized' => const AppException(
      code: 'permission-denied',
      message: 'Bạn không có quyền truy cập tệp báo cáo này.',
    ),
    'canceled' => const AppException(
      code: 'cancelled',
      message: 'Đã hủy tải báo cáo lên Cloud Storage.',
    ),
    'object-not-found' => const AppException(
      code: 'NOT_FOUND',
      message: 'Không tìm thấy tệp báo cáo trên Cloud Storage.',
    ),
    'retry-limit-exceeded' || 'unavailable' => const AppException(
      code: 'network_request_failed',
      message: 'Không kết nối được Cloud Storage. Kiểm tra mạng và thử lại.',
    ),
    _ => const AppException(
      code: 'report_failed',
      message: 'Không thể hoàn tất thao tác Cloud Storage. Vui lòng thử lại.',
    ),
  };
}
