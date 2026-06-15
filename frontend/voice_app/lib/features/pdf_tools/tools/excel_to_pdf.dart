import 'package:flutter/material.dart';
import '../screens/pdf_tool_screen.dart';

class ExcelToPdfTool extends StatelessWidget {
  const ExcelToPdfTool({super.key});

  @override
  Widget build(BuildContext context) {
    return const PdfToolScreen(
      title: 'Excel to PDF',
      description: 'Make EXCEL spreadsheets easy to read by converting them to PDF.',
      icon: Icons.grid_on,
      baseColor: Color(0xFFFF4D4D),
    );
  }
}
