import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatService {
  static const String _baseUrl =
      "https://api.groq.com/openai/v1/chat/completions";

  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? "";

  static Future<String> sendMessage(
    List<Map<String, dynamic>> messages, {
    bool hasImage = false,
  }) async {
    final url = Uri.parse(_baseUrl);

    final List<Map<String, dynamic>> finalMessages = [
      {
        "role": "system",
        "content":
            "Senin adın A.R.I.A. Beyza tarafından geliştirilmiş çok zeki, kibar ve profesyonel bir yapay zeka asistanısın. Kullanıcıya her zaman yardım etmeye hazırsın. Cevapların sesli (TTS) olarak da okunacağı için asla çok uzun destanlar yazma. Mümkün olduğunca kısa, net, samimi ve akıcı bir Türkçe kullan. Kod veya teknik analiz istendiğinde doğrudan konuya gir ve gereksiz laf kalabalığı yapma.",
      },
      ...messages,
    ];

    final String modelToUse = hasImage
        ? "meta-llama/llama-4-scout-17b-16e-instruct"
        : "llama-3.3-70b-versatile";

    final body = json.encode({
      "model": modelToUse,
      "messages": finalMessages,
      if (hasImage) "max_tokens": 1024,
    });

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception(
        "API'den cevap alınamadı.\nHata Kodu: ${response.statusCode}\nDetay: ${response.body}",
      );
    }
  }
}
