abstract interface class MessagingService {
  Future<bool> requestPermission();
  Future<String?> getToken();
}
