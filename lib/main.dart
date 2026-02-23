import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  runApp(const AnlAIApp());
}

class AnlAIApp extends StatelessWidget {
  const AnlAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'AnlAI',
      debugShowCheckedModeBanner: false,

      home: ChatScreen(),
    );
  }
}
