import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;
import 'dart:convert';
import '../../../shared/utils/responsive.dart';

class PdfToolScreen extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color baseColor;

  const PdfToolScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.baseColor = const Color(0xFFE53935),
  });

  @override
  State<PdfToolScreen> createState() => _PdfToolScreenState();
}

class _PdfToolScreenState extends State<PdfToolScreen> {
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
    if (t.contains('compress')) return '/pdf/compress';
    if (t.contains('to word')) return '/pdf/to-word';
    if (t.contains('to excel')) return '/pdf/to-excel';
    if (t.contains('word to pdf')) return '/pdf/word-to-pdf';
    if (t.contains('powerpoint to pdf')) return '/pdf/ppt-to-pdf';
    if (t.contains('excel to pdf')) return '/pdf/excel-to-pdf';
    return '/pdf/merge'; // fallback
  }

  String _getOutputExtension() {
    String t = widget.title.toLowerCase();
    if (t.contains('to word')) return '.docx';
    if (t.contains('to excel')) return '.xlsx';
    if (t.contains('split')) return '.zip';
    return '.pdf';
  }


  @override
  Widget build(BuildContext context) {
    final bool isMob = Responsive.isMobile(context);
    final double titleSize = isMob ? 24 : 36;
    final double descSize = isMob ? 14 : 18;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title.toUpperCase(),
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: descSize,
                    color: const Color(0xFF666666),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_status != null) ...[
                  const SizedBox(height: 16),
                  Text(_status!, style: TextStyle(color: _status!.contains('Error') ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 48),
                if (_isLoading) 
                  const CircularProgressIndicator()
                else
                  _buildModernUploadBox(),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernUploadBox() {
    final bool isMob = Responsive.isMobile(context);
    final double boxHeight = isMob ? 220 : 300;
    final double iconSize = isMob ? 60 : 80;
    final double labelSize = isMob ? 16 : 20;
    final double buttonTextSize = isMob ? 18 : 22;
    final EdgeInsets buttonPadding = isMob 
        ? const EdgeInsets.symmetric(horizontal: 36, vertical: 14)
        : const EdgeInsets.symmetric(horizontal: 48, vertical: 18);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      height: boxHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDDDDD),
          width: 2,
          style: BorderStyle.solid,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined, size: iconSize, color: widget.baseColor),
          SizedBox(height: isMob ? 12 : 24),
          Text(
            isMob ? 'Upload your file' : 'Drag & Drop your file here',
            style: TextStyle(fontSize: labelSize, color: const Color(0xFF666666), fontWeight: FontWeight.w500),
          ),
          SizedBox(height: isMob ? 20 : 32),
          Material(
            color: widget.baseColor,
            borderRadius: BorderRadius.circular(12),
            elevation: 4,
            child: InkWell(
              onTap: _pickAndProcess,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: buttonPadding,
                child: Text(
                  'Select File',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: buttonTextSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
