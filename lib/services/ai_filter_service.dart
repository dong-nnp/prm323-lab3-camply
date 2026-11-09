abstract interface class AiFilterService {
  Future<String> suggest(String keywords, Map<String, List<String>> choices);
}
