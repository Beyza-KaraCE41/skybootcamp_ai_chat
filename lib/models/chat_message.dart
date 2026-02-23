class ChatMessage {
  final String role;
  final String content;
  final String? base64Image;

  ChatMessage({required this.role, required this.content, this.base64Image});

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] ?? 'assistant',
      content: json['content'] is String ? json['content'] : 'Görsel İçerik',
    );
  }

  Map<String, dynamic> toJson() {
    if (base64Image != null) {
      String mimeType = 'image/jpeg';

      if (base64Image!.startsWith('iVBORw0')) {
        mimeType = 'image/png';
      } else if (base64Image!.startsWith('R0lGOD')) {
        mimeType = 'image/gif';
      } else if (base64Image!.startsWith('UklGR')) {
        mimeType = 'image/webp';
      }

      return {
        'role': role,
        'content': [
          {
            "type": "text",
            "text": content.isEmpty ? "Bu resimde ne görüyorsun?" : content,
          },
          {
            "type": "image_url",
            "image_url": {"url": "data:$mimeType;base64,$base64Image"},
          },
        ],
      };
    } else {
      return {'role': role, 'content': content};
    }
  }
}
