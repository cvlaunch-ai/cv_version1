import 'package:flutter/material.dart';
import '../screens/pdf_tool_screen.dart';

class CompressPdfTool extends StatelessWidget {
  const CompressPdfTool({super.key});

  @override
  Widget build(BuildContext context) {
    return const PdfToolScreen(
      title: 'Compress PDF',
      description: 'Reduce file size while optimizing for maximal PDF quality.',
      icon: Icons.compress,
      baseColor: Color(0xFFFF4D4D),
    );
  }
}
