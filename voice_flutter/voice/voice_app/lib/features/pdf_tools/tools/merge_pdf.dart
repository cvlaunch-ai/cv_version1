import 'package:flutter/material.dart';
import '../screens/pdf_tool_screen.dart';

class MergePdfTool extends StatelessWidget {
  const MergePdfTool({super.key});

  @override
  Widget build(BuildContext context) {
    return const PdfToolScreen(
      title: 'Merge PDF',
      description: 'Combine PDFs in the order you want with the easiest PDF merger available.',
      icon: Icons.call_merge,
      baseColor: Color(0xFFFF4D4D),
    );
  }
}
