/// Simple translation helper. In a production app, you'd call Google Translate 
/// or OpenAI API here. For now, it provides a smart simulation.
class TranslationService {
  static Future<String> translate(String text, String targetLang) async {
    // Simulating API Latency
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Simple Mock Logic
    final lower = text.toLowerCase();
    if (lower.contains('how are you')) return "आप कैसे हैं? (Hindi)";
    if (lower.contains('i love you')) return "मैं आपसे प्यार करता हूँ (Hindi)";
    if (lower.contains('hello')) return "नमस्ते (Hindi)";
    
    return "[Translated to $targetLang]: $text";
  }
}
