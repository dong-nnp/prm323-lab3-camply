abstract interface class MessagingService {
  Future<bool> requestPermission();
  Future<String?> getToken();
  Stream<String> get tokenChanges;
  Stream<Map<String, String>> get foregroundMessages;
  Stream<Map<String, String>> get openedMessages;
  Future<Map<String, String>?> initialMessage();
  Future<void> disable();
}
