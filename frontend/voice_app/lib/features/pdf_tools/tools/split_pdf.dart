import 'package:flutter/material.dart';
import '../screens/pdf_tool_screen.dart';

class SplitPdfTool extends StatelessWidget {
  const SplitPdfTool({super.key});

  @override
  Widget build(BuildContext context) {
    return const PdfToolScreen(
      title: 'Split PDF',
      description: 'Separate one page or a whole set for easy conversion into independent PDF files.',
      icon: Icons.call_split,
      baseColor: Color(0xFFFF4D4D),
    );
  }
}
