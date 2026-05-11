import 'package:flutter/material.dart';
import '../screens/pdf_tool_screen.dart';

class PdfToWordTool extends StatelessWidget {
  const PdfToWordTool({super.key});

  @override
  Widget build(BuildContext context) {
    return const PdfToolScreen(
      title: 'PDF to Word',
      description: 'Easily convert your PDF files into easy to edit DOC and DOCX documents.',
      icon: Icons.description,
      baseColor: Color(0xFFFF4D4D),
    );
  }
}
