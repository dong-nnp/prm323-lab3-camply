/// JSON callable transport. Authentication and SDK errors are handled by the adapter.
abstract interface class BackendService {
  Future<Map<String, dynamic>> call(
    String operation, [
    Map<String, dynamic> input = const {},
  ]);
}
