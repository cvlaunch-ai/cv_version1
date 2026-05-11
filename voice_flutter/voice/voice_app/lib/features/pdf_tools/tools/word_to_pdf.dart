import 'package:flutter/material.dart';
import '../screens/pdf_tool_screen.dart';

class WordToPdfTool extends StatelessWidget {
  const WordToPdfTool({super.key});

  @override
  Widget build(BuildContext context) {
    return const PdfToolScreen(
      title: 'Word to PDF',
      description: 'Make DOC and DOCX files easy to read by converting them to PDF.',
      icon: Icons.picture_as_pdf,
      baseColor: Color(0xFFFF4D4D),
    );
  }
}
