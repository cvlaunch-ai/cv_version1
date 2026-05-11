import 'package:flutter/material.dart';
import '../screens/pdf_tool_screen.dart';

class PdfToExcelTool extends StatelessWidget {
  const PdfToExcelTool({super.key});

  @override
  Widget build(BuildContext context) {
    return const PdfToolScreen(
      title: 'PDF to Excel',
      description: 'Pull data straight from PDFs into Excel spreadsheets in a few short seconds.',
      icon: Icons.table_chart,
      baseColor: Color(0xFFFF4D4D),
    );
  }
}
