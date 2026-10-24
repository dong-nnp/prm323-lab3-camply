/// A safe, user-facing error. SDK exceptions stay inside the service layer.
class AppException implements Exception {
  const AppException({required this.code, required this.message});

  final String code;
  final String message;

  @override
  String toString() => 'AppException($code): $message';
}
