import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html; // Standard for Flutter Web
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/voice_orb.dart';
import '../../../shared/utils/responsive.dart';

class ResumeGeneratorScreen extends StatefulWidget {
  const ResumeGeneratorScreen({super.key});

  @override
  State<ResumeGeneratorScreen> createState() => _ResumeGeneratorScreenState();
}

class _ResumeGeneratorScreenState extends State<ResumeGeneratorScreen> {
  bool _isSpeakMode = true; 
  int _activeWriteTab = 0;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _capturedText = "";
  final TextEditingController _transcriptionController = TextEditingController();
  bool _hasGenerated = false; // Added this missing variable
  
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text': "Hello! I'm your AI Resume Builder 🚀 I'll help you craft a stunning, ATS-optimized resume. Let's start — what's your full name and targeting role?"
    }
  ];
  
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAITyping = false;
  bool _isReadyToGenerate = false; // AI has collected enough info
  String _resumePreview = "";
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
      bool available = await _speech.initialize(
        onStatus: (status) {
          print('STT Status: $status');
          // Automatically process when user stops speaking naturally
          if (status == 'done' || status == 'notListening') {
            if (_isListening && _isSpeakMode) {
              setState(() => _isListening = false);
              _handleSpeakToResume();
            }
          }
        },
        onError: (error) => print('STT Error: $error'),
      );
      
      if (available) {
        setState(() {
          _isListening = true;
          _transcriptionController.clear();
          _capturedText = ""; 
          _hasGenerated = false;
          _resumePreview = "";
        });
        
        _speech.listen(
          onResult: (val) {
            setState(() {
              _capturedText = val.recognizedWords;
              _transcriptionController.text = _capturedText;
              _transcriptionController.selection = TextSelection.fromPosition(
                TextPosition(offset: _transcriptionController.text.length),
              );
            });
          },
          listenFor: const Duration(seconds: 60),
          pauseFor: const Duration(seconds: 5),
          partialResults: true,
          listenMode: stt.ListenMode.dictation,
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_isSpeakMode) _handleSpeakToResume();
    }
  }

  Future<void> _handleSpeakToResume() async {
    if (_capturedText.isEmpty) return;
    
    setState(() => _isAITyping = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-resume-json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _capturedText,
          'template_id': 'classic'
        }),
      );
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _resumePreview = result['resume'] ?? "";
          _hasGenerated = true;
          _transcriptionController.text = _resumePreview;
        });
      }
    } catch (e) {
      print("Speak Error: $e");
    } finally {
      setState(() {
        _isAITyping = false;
        _isListening = false;
      });
    }
  }

  Future<void> _downloadResume() async {
    if (_resumePreview.isEmpty) return;
    
    setState(() => _isAITyping = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-resume-pdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _resumePreview,
          'template_id': 'classic'
        }),
      );
      
      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "resume.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      print("Download Error: $e");
    } finally {
      setState(() => _isAITyping = false);
    }
  }

  void _addMessage(String role, String text) {
    setState(() {
      _messages.add({'role': role, 'text': text});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleUserMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    _chatController.clear();
    _addMessage('user', text);
    setState(() {
      _isAITyping = true;
      // Show the panel immediately on first message
    });
    
    // Trigger live preview update immediately for user text too
    _updateLivePreview();

    try {
      // Use /chat-resume for conversational info collection
      // Only the history BEFORE adding the current message is sent
      final historyForApi = _messages
          .map((m) => {'role': m['role']!, 'text': m['text']!})
          .toList();

      final response = await http.post(
        Uri.parse('$_baseUrl/chat-resume'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': text,
          'history': historyForApi,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final aiMsg = result['message'] ?? "Got it! Tell me more.";
        final ready = result['ready'] == true;
        _addMessage('ai', aiMsg);
        setState(() => _isReadyToGenerate = ready);
        
        // NOW: Also update the resume preview in the background for "Live" feel
        _updateLivePreview();
      } else {
        _addMessage('ai', "Something went wrong. Please try again.");
      }
    } catch (e) {
      _addMessage('ai', "Backend connection error. Please make sure the server is running.");
    } finally {
      setState(() => _isAITyping = false);
    }
  }

  Future<void> _updateLivePreview() async {
    // Build a combined text from all user messages
    final allUserText = _messages
        .where((m) => m['role'] == 'user')
        .map((m) => m['text']!)
        .join('\n');

    if (allUserText.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-resume-json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': allUserText,
          'template_id': 'classic',
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _resumePreview = result['resume'] ?? '';
          _transcriptionController.text = _resumePreview;
        });
      }
    } catch (e) {
      print("Live Preview Error: $e");
    }
  }

  Future<void> _generateResumeFromChat() async {
    // Build a combined text from all user messages
    final allUserText = _messages
        .where((m) => m['role'] == 'user')
        .map((m) => m['text']!)
        .join('\n');

    if (allUserText.isEmpty) return;
    setState(() => _isAITyping = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-resume-json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': allUserText,
          'template_id': 'classic',
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          _resumePreview = result['resume'] ?? '';
          _hasGenerated = true;
        });
      } else {
        _addMessage('ai', "Failed to generate resume. Please try again.");
      }
    } catch (e) {
      _addMessage('ai', "Error generating resume: $e");
    } finally {
      setState(() => _isAITyping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isSpeakMode ? _buildSpeakUI() : _buildWriteUI(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final bool isMob = Responsive.isMobile(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: isMob
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 20),
              child: const Icon(Icons.auto_awesome, color: AppColors.primaryAccent),
            ),
      title: _buildSegmentedControl(),
      centerTitle: true,
      actions: [
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.home, size: 20, color: Colors.white)),
        SizedBox(width: isMob ? 8 : 20),
      ],
    );
  }

  Widget _buildSegmentedControl() {
    final bool isMob = Responsive.isMobile(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSegmentButton(isMob ? "Speak" : "Speak to resume", Icons.mic, _isSpeakMode, () {
            setState(() {
              _isSpeakMode = true;
              _hasGenerated = false;
              _resumePreview = "";
              _capturedText = "";
              _transcriptionController.clear();
            });
          }),
          _buildSegmentButton(isMob ? "Write" : "Write to resume", Icons.edit_document, !_isSpeakMode, () {
            setState(() {
              _isSpeakMode = false;
              _hasGenerated = false;
              _resumePreview = "";
              _isReadyToGenerate = false;
            });
          }),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String label, IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.secondaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakUI() {
    final showRightPanel = _isListening || _capturedText.isNotEmpty || _hasGenerated;
    final bool isMob = Responsive.isMobile(context);

    if (isMob) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "AI resume builder",
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                const SizedBox(height: 12),
                const Text(
                  "Have a conversation, Get a stunning resume",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 40),
                VoiceOrb(isListening: _isListening),
                const SizedBox(height: 40),
                CustomButton(
                  text: _isListening ? "Listening..." : (_hasGenerated ? "Restart Voice" : "Tap to speak"),
                  onPressed: () {
                    if (_isAITyping) return;
                    if (_hasGenerated) {
                      setState(() {
                        _hasGenerated = false;
                        _capturedText = "";
                        _resumePreview = "";
                        _transcriptionController.clear();
                      });
                    }
                    _toggleListening();
                  },
                ).animate().scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                if (_isAITyping)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(color: AppColors.primaryAccent),
                  ),
              ],
            ),
            if (showRightPanel) ...[
              const SizedBox(height: 32),
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0F1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _hasGenerated ? Icons.description : Icons.format_quote,
                            color: AppColors.primaryAccent,
                            size: 32,
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: _isAITyping 
                              ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                              : TextField(
                                  controller: _transcriptionController,
                                  maxLines: null,
                                  readOnly: _hasGenerated,
                                  textAlign: _hasGenerated ? TextAlign.left : TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _hasGenerated ? 12 : 18,
                                    fontWeight: FontWeight.w300,
                                    fontFamily: _hasGenerated ? 'monospace' : null,
                                    height: 1.5,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: _isListening ? "I'm listening..." : "Your text here...",
                                    hintStyle: const TextStyle(color: Colors.white24),
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      _capturedText = val;
                                      if (_hasGenerated) _resumePreview = val;
                                    });
                                  },
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (_hasGenerated)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: IconButton(
                          onPressed: _downloadResume,
                          icon: const Icon(Icons.download_for_offline, color: AppColors.primaryAccent, size: 28),
                          tooltip: "Download PDF",
                        ).animate().fadeIn().slideX(begin: 0.5, end: 0),
                      ),
                  ],
                ),
              ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            flex: showRightPanel ? 5 : 10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "AI resume builder",
                  style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
                const SizedBox(height: 12),
                const Text(
                  "Have a conversation, Get a stunning resume",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 60),
                VoiceOrb(isListening: _isListening),
                const SizedBox(height: 60),
                CustomButton(
                  text: _isListening ? "Listening..." : (_hasGenerated ? "Restart Voice" : "Tap to speak"),
                  onPressed: () {
                    if (_isAITyping) return;
                    if (_hasGenerated) {
                      setState(() {
                        _hasGenerated = false;
                        _capturedText = "";
                        _resumePreview = "";
                        _transcriptionController.clear();
                      });
                    }
                    _toggleListening();
                  },
                ).animate().scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                if (_isAITyping)
                  const Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: CircularProgressIndicator(color: AppColors.primaryAccent),
                  ),
              ],
            ),
          ),
          
          if (showRightPanel)
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0F1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasGenerated ? Icons.description : Icons.format_quote,
                              color: AppColors.primaryAccent,
                              size: 40,
                            ),
                            const SizedBox(height: 20),
                             Expanded(
                                child: _isAITyping 
                                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                                  : TextField(
                                      controller: _transcriptionController,
                                      maxLines: null,
                                      readOnly: _hasGenerated,
                                      textAlign: _hasGenerated ? TextAlign.left : TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: _hasGenerated ? 13 : 22,
                                        fontWeight: FontWeight.w300,
                                        fontFamily: _hasGenerated ? 'monospace' : null,
                                        height: 1.5,
                                      ),
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: _isListening ? "I'm listening..." : "Your text here...",
                                        hintStyle: const TextStyle(color: Colors.white24),
                                      ),
                                      onChanged: (val) {
                                        setState(() {
                                          _capturedText = val;
                                          if (_hasGenerated) _resumePreview = val;
                                        });
                                      },
                                    ),
                              ),
                            ],
                          ),
                        ),
                      if (_hasGenerated)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: IconButton(
                            onPressed: _downloadResume,
                            icon: const Icon(Icons.download_for_offline, color: AppColors.primaryAccent, size: 28),
                            tooltip: "Download PDF",
                          ).animate().fadeIn().slideX(begin: 0.5, end: 0),
                        ),
                    ],
                  ),
                ),
              ).animate().slideX(begin: 1.0, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
            ),
        ],
      ),
    );
  }

  Widget _buildWriteUI() {
    final bool showRightPanel = _messages.length > 1;
    final bool isMob = Responsive.isMobile(context);

    if (isMob) {
      return Column(
        children: [
          _buildWriteTabBar(showRightPanel),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _activeWriteTab == 0
                  ? _buildChatSection()
                  : (showRightPanel 
                      ? _buildPreviewSection() 
                      : _buildEmptyPreviewPlaceholder()),
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: _buildChatSection(),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 5,
            child: showRightPanel 
              ? _buildPreviewSection().animate().fadeIn().slideX(begin: 0.1, end: 0)
              : _buildEmptyPreviewPlaceholder(),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteTabBar(bool showRightPanel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeWriteTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeWriteTab == 0 ? AppColors.secondaryAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    "Chat Editor",
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeWriteTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeWriteTab == 1 ? AppColors.secondaryAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    showRightPanel ? "Live Preview ✨" : "Preview",
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPreviewPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, color: Colors.white.withOpacity(0.1), size: 64),
            const SizedBox(height: 20),
            Text(
              "Your live resume will appear here",
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.description,
                  color: AppColors.primaryAccent,
                  size: 40,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _isAITyping 
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent))
                    : TextField(
                        controller: _transcriptionController,
                        maxLines: null,
                        readOnly: true,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Waiting for your information...",
                          hintStyle: TextStyle(color: Colors.white24),
                        ),
                      ),
                ),
              ],
            ),
          ),
          if (_resumePreview.isNotEmpty)
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: _downloadResume,
                icon: const Icon(Icons.download_for_offline, color: AppColors.primaryAccent, size: 28),
                tooltip: "Download PDF",
              ).animate().fadeIn().slideX(begin: 0.5, end: 0),
            ),
        ],
      ),
    );
  }

  Widget _buildChatSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildDot(Colors.red), const SizedBox(width: 8),
                _buildDot(Colors.orange), const SizedBox(width: 8),
                _buildDot(Colors.green),
                const SizedBox(width: 16),
                const Text("Resume AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _messages.length + (_isAITyping ? 1 : 0),
              itemBuilder: (context, index) {
                // Show typing indicator as last item
                if (index == _messages.length) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.auto_awesome, size: 16, color: AppColors.primaryAccent),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.02),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: const SizedBox(
                            width: 40,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                // Normal message
                if (index == _messages.length) return const SizedBox.shrink();
                final msg = _messages[index];
                return _buildChatMessage(msg['role']!, msg['text']!);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) => Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _buildChatMessage(String role, String text) {
    final isAI = role == 'ai';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isAI ? AppColors.primaryAccent.withOpacity(0.1) : AppColors.secondaryAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(isAI ? Icons.auto_awesome : Icons.person, size: 16, color: isAI ? AppColors.primaryAccent : AppColors.secondaryAccent),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(0.05))),
              child: Text(text, style: const TextStyle(color: Colors.white, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Generate Resume button — shown when AI has collected enough info
          if (_isReadyToGenerate && !_hasGenerated)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _isAITyping
                  ? const SizedBox.shrink()
                  : GestureDetector(
                      onTap: _generateResumeFromChat,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryAccent, AppColors.secondaryAccent],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryAccent.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Generate Resume 🪄',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),
            ),
          // Text input row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mic, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Type your answer...",
                      hintStyle: TextStyle(color: AppColors.textMuted),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleUserMessage(),
                  ),
                ),
                IconButton(
                  onPressed: _isAITyping ? null : _handleUserMessage,
                  icon: Icon(
                    Icons.send,
                    color: _isAITyping ? AppColors.textMuted.withOpacity(0.3) : AppColors.primaryAccent,
                    size: 20,
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
