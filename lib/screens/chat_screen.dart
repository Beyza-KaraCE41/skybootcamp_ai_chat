import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:convert';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../services/chat_service.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final List<String> _savedNotes = [];

  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;

  // YENİ: Ses araçları
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  final Color _accentColor = const Color(0xFF64FFDA);
  final Color _secondaryColor = const Color(0xFF82B1FF);
  final Color _darkBackground = const Color(0xFF0A192F);
  final Color _darkerBackground = const Color(0xFF020C1B);

  @override
  void initState() {
    super.initState();
    _loadSavedNotes();
    _initTts(); // Sesli okuma motorunu başlat
  }

  // YENİ: Sesli Okuma Ayarları (Türkçe)
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("tr-TR");
    await _flutterTts.setPitch(1.1); // Ses inceliği
    await _flutterTts.setSpeechRate(0.5); // Konuşma hızı
  }

  // YENİ: Metni Sese Çevirip Okuma Fonksiyonu
  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _flutterTts.speak(text);
      _flutterTts.setCompletionHandler(() {
        setState(() => _isSpeaking = false);
      });
    }
  }

  // YENİ: Mikrofonu dinleme fonksiyonu
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _messageController.text = val.recognizedWords; // Sesi kutuya yazdır
          }),
          localeId: 'tr_TR', // Türkçe dinle
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _loadSavedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedNotes.clear();
      _savedNotes.addAll(prefs.getStringList('my_ai_notes') ?? []);
    });
  }

  Future<void> _saveNoteToMemory(String note) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_savedNotes.contains(note)) {
      setState(() {
        _savedNotes.add(note);
      });
      await prefs.setStringList('my_ai_notes', _savedNotes);
      _showSnackBar('Not defterine kaydedildi', Icons.bookmark_added_rounded);
    } else {
      _showSnackBar('Bu not zaten kayıtlı!', Icons.info_outline_rounded);
    }
  }

  Future<void> _deleteNote(String note) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedNotes.remove(note);
    });
    await prefs.setStringList('my_ai_notes', _savedNotes);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      _showSnackBar('Resim seçilemedi: $e', Icons.error_outline_rounded);
    }
  }

  void _removeSelectedImage() {
    setState(() {
      _selectedImageBytes = null;
    });
  }

  Future<void> _sendMessage([String? suggestionText]) async {
    final text = suggestionText ?? _messageController.text.trim();
    if (text.isEmpty && _selectedImageBytes == null) return;

    final sentText = text;
    final sentImageBytes = _selectedImageBytes;

    _messageController.clear();
    _removeSelectedImage();
    _focusNode.requestFocus();
    if (_isListening) {
      _speech.stop();
      setState(() => _isListening = false);
    }

    String? base64String;
    if (sentImageBytes != null) {
      base64String = base64Encode(sentImageBytes);
    }

    setState(() {
      _messages.add(
        ChatMessage(role: 'user', content: sentText, base64Image: base64String),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final apiMessages = _messages.map((m) => m.toJson()).toList();
      final response = await ChatService.sendMessage(
        apiMessages,
        hasImage: base64String != null,
      );

      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: response));
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(role: 'assistant', content: 'Hata oluştu: $e'),
        );
      });
    } finally {
      setState(() {
        _isLoading = false;
        _scrollToBottom();
      });
    }
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
    });
  }

  void _goToSavedMessages() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedNotesScreen(
          savedNotes: _savedNotes,
          accentColor: _accentColor,
          darkBackground: _darkBackground,
          darkerBackground: _darkerBackground,
          onDelete: _deleteNote,
        ),
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _flutterTts.stop(); // Uygulama kapanınca sesi durdur
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _darkBackground,
                  const Color(0xFF112240),
                  _darkerBackground,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessageList(),
                ),
                if (_isLoading) _buildLoadingIndicator(),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [_accentColor, _secondaryColor],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.3),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: _darkBackground,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A.R.I.A.',
                      style: GoogleFonts.nunito(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _accentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _accentColor.withOpacity(0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sistem Aktif',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: _accentColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _goToSavedMessages,
                tooltip: 'Not Defteri',
                icon: Icon(
                  Icons.edit_note_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 28,
                ),
              ),
              if (_messages.isNotEmpty)
                IconButton(
                  onPressed: _clearChat,
                  tooltip: 'Sohbeti Temizle',
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Lottie.asset(
                'assets/animations/ai_chat.json',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sisteme Hoş Geldin',
              style: GoogleFonts.nunito(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Projen için neye ihtiyacın var?",
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  _buildSuggestionChip(
                    'Kendini Tanıt',
                    Icons.waving_hand_rounded,
                  ),
                  _buildSuggestionChip(
                    'Fıkra Anlat',
                    Icons.sentiment_very_satisfied_rounded,
                  ),
                  _buildSuggestionChip('Kod Analizi', Icons.analytics_outlined),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withOpacity(0.05),
          child: InkWell(
            onTap: () => _sendMessage(text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: _accentColor),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isUser = message.role == 'user';
        final isFirstInGroup =
            index == 0 || _messages[index - 1].role != message.role;

        return Padding(
          padding: EdgeInsets.only(top: isFirstInGroup ? 16 : 4),
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (isFirstInGroup)
                Padding(
                  padding: EdgeInsets.only(
                    left: isUser ? 0 : 4,
                    right: isUser ? 4 : 0,
                    bottom: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isUser) ...[
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            gradient: LinearGradient(
                              colors: [_accentColor, _secondaryColor],
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: _darkBackground,
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        isUser ? 'Sen' : 'A.R.I.A.',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              _buildMessageBubble(message, isUser),
            ],
          ),
        );
      },
    );
  }

  void _showMessageOptions(String content) {
    if (content.isEmpty) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF112240),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(Icons.copy_rounded, color: _accentColor),
                title: Text(
                  'Metni Kopyala',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: content));
                  Navigator.pop(context);
                  _showSnackBar(
                    'Panoya kopyalandı',
                    Icons.check_circle_rounded,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.bookmark_add_rounded, color: _accentColor),
                title: Text(
                  'Not Defterine Kaydet',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _saveNoteToMemory(content);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String text, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: _darkBackground, size: 20),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.nunito(
                color: _darkBackground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        backgroundColor: _accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isUser) {
    return GestureDetector(
      onLongPress: () => _showMessageOptions(message.content),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 18),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isUser ? 0 : 10,
              sigmaY: isUser ? 0 : 10,
            ),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isUser
                    ? LinearGradient(
                        colors: [
                          _secondaryColor.withOpacity(0.8),
                          _accentColor.withOpacity(0.6),
                        ],
                      )
                    : null,
                color: isUser ? null : Colors.white.withOpacity(0.05),
                border: isUser
                    ? null
                    : Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: isUser
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (message.base64Image != null)
                    Container(
                      margin: EdgeInsets.only(
                        bottom: message.content.isNotEmpty ? 10 : 0,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(message.base64Image!),
                          width: 220,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  if (message.content.isNotEmpty)
                    Text(
                      message.content,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),

                  // YENİ: YAPAY ZEKA MESAJIYSA HOPARLÖR BUTONU GÖSTER
                  if (!isUser && message.content.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: InkWell(
                        onTap: () => _speak(message.content),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volume_up_rounded,
                              color: _accentColor.withOpacity(0.8),
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sesli Dinle',
                              style: GoogleFonts.nunito(
                                color: _accentColor.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              gradient: LinearGradient(colors: [_accentColor, _secondaryColor]),
            ),
            child: Icon(Icons.auto_awesome, color: _darkBackground, size: 13),
          ),
          const SizedBox(width: 12),
          Text(
            'Veriler işleniyor...',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: _accentColor,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedImageBytes != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _accentColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImageBytes!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _removeSelectedImage,
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: _pickImage,
                            icon: Icon(
                              Icons.attach_file_rounded,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            tooltip: 'Resim Ekle',
                          ),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              focusNode: _focusNode,
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                hintText: _isListening
                                    ? 'Sizi dinliyorum...'
                                    : 'Sisteme komut gönder...',
                                hintStyle: GoogleFonts.nunito(
                                  color: _isListening
                                      ? _accentColor
                                      : Colors.white54,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: _isListening
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.only(
                                  top: 14,
                                  bottom: 14,
                                  right: 10,
                                ),
                              ),
                            ),
                          ),
                          // MİKROFON BUTONU
                          IconButton(
                            onPressed: _listen,
                            icon: Icon(
                              _isListening
                                  ? Icons.mic_rounded
                                  : Icons.mic_none_rounded,
                              color: _isListening
                                  ? _secondaryColor
                                  : Colors.white.withOpacity(0.7),
                            ),
                            tooltip: 'Konuşarak Yaz',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : () => _sendMessage(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_accentColor, _secondaryColor],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _accentColor.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.send_rounded,
                          color: _darkBackground,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// NOT DEFTERİ EKRANI
// ============================================================================
class SavedNotesScreen extends StatefulWidget {
  final List<String> savedNotes;
  final Color accentColor;
  final Color darkBackground;
  final Color darkerBackground;
  final Function(String) onDelete;

  const SavedNotesScreen({
    super.key,
    required this.savedNotes,
    required this.accentColor,
    required this.darkBackground,
    required this.darkerBackground,
    required this.onDelete,
  });

  @override
  State<SavedNotesScreen> createState() => _SavedNotesScreenState();
}

class _SavedNotesScreenState extends State<SavedNotesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.darkBackground,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.darkBackground,
                  const Color(0xFF112240),
                  widget.darkerBackground,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit_note_rounded,
                        color: widget.accentColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sistem Notları',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: widget.savedNotes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.speaker_notes_off_rounded,
                                size: 60,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz Eklenmiş Not Yok!.',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: widget.savedNotes.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border(
                                  left: BorderSide(
                                    color: widget.accentColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.savedNotes[index],
                                      style: GoogleFonts.nunito(
                                        color: Colors.white,
                                        fontSize: 15,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.white54,
                                    ),
                                    onPressed: () {
                                      widget.onDelete(widget.savedNotes[index]);
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
