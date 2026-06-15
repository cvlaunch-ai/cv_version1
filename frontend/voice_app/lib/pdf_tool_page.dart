import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme/app_theme.dart';
import 'shared/widgets/custom_button.dart';

class PdfToolPage extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color baseColor;

  const PdfToolPage({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.baseColor = AppColors.primaryAccent,
  });

  @override
  State<PdfToolPage> createState() => _PdfToolPageState();
}

class _PdfToolPageState extends State<PdfToolPage> {
  bool _isLoading = false;
  String? _status;
  final String _baseUrl = 'http://127.0.0.1:8001';

  Future<void> _pickAndProcess() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'],
      allowMultiple: widget.title.contains('Merge'),
    );

    if (result != null) {
      setState(() {
        _isLoading = true;
        _status = "Processing ${result.files.first.name}...";
      });

      try {
        String endpoint = _getEndpoint();
        var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$endpoint'));
        
        for (var file in result.files) {
          if (file.bytes != null) {
            request.files.add(http.MultipartFile.fromBytes(
              'file' + (widget.title.contains('Merge') ? 's' : ''),
              file.bytes!,
              filename: file.name,
            ));
          }
        }

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          if (response.headers['content-type']?.contains('application/json') ?? false) {
             final errorData = jsonDecode(response.body);
             if (errorData['error'] != null) {
                setState(() => _status = "Error: ${errorData['error']}");
                return;
             }
          }
          
          final blob = html.Blob([response.bodyBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final extension = _getOutputExtension();
          
          html.AnchorElement(href: url)
            ..setAttribute('download', "processed_file$extension")
            ..click();
          html.Url.revokeObjectUrl(url);
          
          setState(() => _status = "Success! File Downloaded.");
        } else {
          setState(() => _status = "Server Error: ${response.statusCode}");
        }
      } catch (e) {
        setState(() => _status = "Error: $e");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getEndpoint() {
    String t = widget.title.toLowerCase();
    if (t.contains('merge')) return '/pdf/merge';
    if (t.contains('split')) return '/pdf/split';
    if (t.contains('to word')) return '/pdf/to-word';
    if (t.contains('word to pdf')) return '/pdf/word-to-pdf';
    return '/pdf/merge'; // fallback
  }

  String _getOutputExtension() {
    String t = widget.title.toLowerCase();
    if (t.contains('to word')) return '.docx';
    if (t.contains('split')) return '.zip';
    return '.pdf';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Subtle glow
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryAccent.withOpacity(0.05),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 4.seconds)
              .blurXY(begin: 80, end: 100),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                      child: Text(
                        widget.title.toUpperCase(),
                        style: AppTheme.headlineStyle.copyWith(fontSize: 48, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.textMuted,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms),
                    if (_status != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _status!.contains('Error') ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _status!.contains('Error') ? Colors.red : Colors.green, width: 0.5),
                        ),
                        child: Text(
                          _status!,
                          style: TextStyle(
                            color: _status!.contains('Error') ? Colors.redAccent : Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ).animate().shake(),
                    ],
                    const SizedBox(height: 48),
                    if (_isLoading) 
                      const CircularProgressIndicator(color: AppColors.primaryAccent)
                    else
                      _buildModernUploadBox(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernUploadBox() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      height: 320,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
            child: Icon(widget.icon, size: 80, color: Colors.white),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
          const SizedBox(height: 24),
          const Text(
            'Drag & Drop your file here',
            style: TextStyle(fontSize: 20, color: AppColors.textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Select File',
            onPressed: _pickAndProcess,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }
}
