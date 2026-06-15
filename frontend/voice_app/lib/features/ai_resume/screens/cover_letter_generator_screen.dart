import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';

class CoverLetterGeneratorScreen extends StatefulWidget {
  const CoverLetterGeneratorScreen({super.key});

  @override
  State<CoverLetterGeneratorScreen> createState() => _CoverLetterGeneratorScreenState();
}

class _CoverLetterGeneratorScreenState extends State<CoverLetterGeneratorScreen> {
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text': "Ready to write a cover letter that gets you hired? ✍️ Tell me about the company and the specific job role you're applying for!"
    }
  ];
  
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAITyping = false;
  String _previewContent = "Your cover letter will appear here as we chat...";
  final String _baseUrl = 'http://127.0.0.1:8001';

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
    setState(() => _isAITyping = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-cover-letter-json'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'history': _messages.map((m) => "${m['role']}: ${m['text']}").join("\n")
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _addMessage('ai', "I've drafted a cover letter based on that! How does it look?");
        setState(() {
          _previewContent = result['cover_letter'];
        });
      }
    } catch (e) {
      _addMessage('ai', "Error connecting to backend.");
    } finally {
      setState(() => _isAITyping = false);
    }
  }

  Future<void> _downloadPDF() async {
    if (_previewContent.contains("appear here")) return;
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-cover-letter-pdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': _previewContent}),
      );
      
      final blob = html.Blob([response.bodyBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)..setAttribute('download', 'cover_letter.pdf')..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error downloading PDF")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Row(
        children: [
          Expanded(flex: 5, child: _buildChatSection()),
          Container(width: 1, color: AppColors.border.withOpacity(0.1)),
          Expanded(flex: 5, child: _buildPreviewSection()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background.withOpacity(0.8),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.border.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_document, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              "Write cover letter",
              style: AppTheme.logoStyle.copyWith(fontSize: 14, letterSpacing: 1),
            ),
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        CustomButton(text: 'Download', onPressed: _downloadPDF, isOutlined: true),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildChatSection() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            itemCount: _messages.length + (_isAITyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isAITyping) return _buildTypingIndicator();
              final msg = _messages[index];
              return _buildChatMessage(msg['role']!, msg['text']!);
            },
          ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildChatMessage(String role, String text) {
    final isAI = role == 'ai';
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (isAI) _buildAvatar(Icons.edit_note, AppColors.tertiaryAccent),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isAI ? AppColors.surface : AppColors.secondaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isAI ? AppColors.border : AppColors.secondaryAccent.withOpacity(0.3)),
              ),
              child: Text(text, style: const TextStyle(color: AppColors.textPrimary)),
            ),
          ).animate().fadeIn(),
          if (!isAI) const SizedBox(width: 12),
          if (!isAI) _buildAvatar(Icons.person, AppColors.secondaryAccent),
        ],
      ),
    );
  }

  Widget _buildAvatar(IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, size: 20, color: color));
  }

  Widget _buildTypingIndicator() {
    return const Padding(padding: EdgeInsets.all(24), child: Text("AI is thinking...", style: TextStyle(color: AppColors.textMuted)));
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              onSubmitted: (_) => _handleUserMessage(),
              decoration: InputDecoration(hintText: "Tell me about the job...", filled: true, fillColor: AppColors.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(onPressed: _handleUserMessage, icon: const Icon(Icons.send, color: AppColors.primaryAccent)),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      color: AppColors.secondaryBG.withOpacity(0.3),
      child: SingleChildScrollView(child: Text(_previewContent, style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'monospace'))),
    );
  }
}
