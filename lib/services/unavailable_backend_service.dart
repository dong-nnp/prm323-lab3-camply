import '../core/errors/app_exception.dart';
import 'backend_service.dart';

class UnavailableBackendService implements BackendService {
  const UnavailableBackendService();
  @override
  Future<Map<String, dynamic>> call(
    String operation, [
    Map<String, dynamic> input = const {},
  ]) async => throw const AppException(
    code: 'backend_unavailable',
    message: 'Firebase is not enabled in this build.',
  );
}
