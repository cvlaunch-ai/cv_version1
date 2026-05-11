import 'package:flutter/material.dart';
import '../screens/pdf_tool_screen.dart';

class PowerPointToPdfTool extends StatelessWidget {
  const PowerPointToPdfTool({super.key});

  @override
  Widget build(BuildContext context) {
    return const PdfToolScreen(
      title: 'PowerPoint to PDF',
      description: 'Make PPT and PPTX slideshows easy to view by converting them to PDF.',
      icon: Icons.slideshow,
      baseColor: Color(0xFFFF4D4D),
    );
  }
}
