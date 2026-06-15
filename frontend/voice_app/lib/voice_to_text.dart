import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'theme/app_theme.dart';
import 'shared/widgets/custom_button.dart';
import 'shared/widgets/voice_orb.dart';

class VoiceToTextPage extends StatefulWidget {
  const VoiceToTextPage({super.key});

  @override
  State<VoiceToTextPage> createState() => _VoiceToTextPageState();
}

class _VoiceToTextPageState extends State<VoiceToTextPage> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _capturedText = "";
  String _statusMessage = "Have a conversation, Get a stunning resume";
  final String _baseUrl = 'http://127.0.0.1:8001';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    await _speech.initialize();
  }

  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _capturedText = "";
          _statusMessage = "Listening to your brilliance...";
        });
        _speech.listen(
          onResult: (val) => setState(() {
            _capturedText = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _statusMessage = "Processing your input...";
      });
      _speech.stop();
      _handleSubmit();
    }
  }

  Future<void> _handleSubmit() async {
    if (_capturedText.isEmpty) return;
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-resume-json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': _capturedText}),
      );
      if (response.statusCode == 200) {
        setState(() => _statusMessage = "Resume details captured!");
      }
    } catch (e) {
      setState(() => _statusMessage = "Error connecting to backend");
    }
  }

  @override
  Widget build(BuildContext context) {
    final showRightPanel = _isListening || _capturedText.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 60),
                  VoiceOrb(isListening: _isListening),
                  const SizedBox(height: 60),
                  CustomButton(
                    text: _isListening ? "Stop & Process" : "Tap to speak",
                    onPressed: _toggleListening,
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              width: showRightPanel ? MediaQuery.of(context).size.width * 0.45 : 0,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0F1E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.format_quote, color: AppColors.primaryAccent, size: 40),
                              const SizedBox(height: 20),
                              Text(
                                _capturedText.isEmpty ? "I'm listening..." : _capturedText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w300,
                                  height: 1.5,
                                ),
                              ).animate(target: _capturedText.isEmpty ? 0 : 1).fadeIn(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text("AI RESUME BUILDER", style: AppTheme.logoStyle.copyWith(fontSize: 16, letterSpacing: 2)),
      centerTitle: true,
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          "AI resume builder",
          style: AppTheme.headlineStyle.copyWith(fontSize: 56),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        Text(
          _statusMessage,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 18),
        ).animate().fadeIn(delay: 300.ms),
      ],
    );
  }
}
