import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'theme/app_theme.dart';
import 'shared/widgets/custom_button.dart';
import 'features/home/widgets/tool_card.dart';
import 'pdf_tool_page.dart';
import 'features/ai_resume/screens/resume_generator_screen.dart';
import 'features/ai_resume/screens/cover_letter_generator_screen.dart';

class PdfHomePage extends StatefulWidget {
  const PdfHomePage({super.key});

  @override
  State<PdfHomePage> createState() => _PdfHomePageState();
}

class _PdfHomePageState extends State<PdfHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // Background Gradient Glow
          Positioned(
            top: -200,
            left: -200,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondaryAccent.withOpacity(0.05),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 7.seconds)
              .blurXY(begin: 100, end: 120),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroSection(),
                _buildToolsGrid(context),
                const SizedBox(height: 80),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background.withOpacity(0.8),
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border.withOpacity(0.1)),
          ),
        ),
      ),
      title: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
            child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 12),
          Text(
            'DOCFORGE AI',
            style: AppTheme.logoStyle,
          ),
        ],
      ),
      actions: [
        CustomButton(
          text: 'AI Resume',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ResumeGeneratorScreen()));
          },
          isOutlined: true,
        ),
        const SizedBox(width: 12),
        CustomButton(
          text: 'AI Cover Letter',
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CoverLetterGeneratorScreen()));
          },
          isOutlined: true,
        ),
        const SizedBox(width: 24),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
            child: Text(
              'Premium Document Engineering',
              textAlign: TextAlign.center,
              style: AppTheme.headlineStyle.copyWith(fontSize: 48, color: Colors.white),
            ),
          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),
          Text(
            'Experience the next generation of PDF management.\nSecure, intelligent, and designed for professionals.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: AppColors.textMuted,
              height: 1.6,
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    final tools = [
      {'name': 'Merge PDF', 'desc': 'Combine multiple PDFs into one document.', 'icon': Icons.call_merge},
      {'name': 'Split PDF', 'desc': 'Extract pages or split your PDF files.', 'icon': Icons.call_split},
      {'name': 'Compress PDF', 'desc': 'Optimize size without quality loss.', 'icon': Icons.compress},
      {'name': 'PDF to Word', 'desc': 'Convert PDFs to editable documents.', 'icon': Icons.description},
      {'name': 'PDF to Excel', 'desc': 'Extract data into structured sheets.', 'icon': Icons.table_chart},
      {'name': 'Word to PDF', 'desc': 'Professional Word to PDF conversion.', 'icon': Icons.picture_as_pdf},
      {'name': 'PPT to PDF', 'desc': 'Transform presentations into PDFs.', 'icon': Icons.slideshow},
      {'name': 'Excel to PDF', 'desc': 'Convert spreadsheets into PDFs.', 'icon': Icons.grid_on},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      constraints: const BoxConstraints(maxWidth: 1400),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 600 ? 2 : 1));
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: 0.9,
            ),
            itemCount: tools.length,
            itemBuilder: (context, index) {
              final tool = tools[index];
              return ToolCard(
                name: tool['name'] as String,
                description: tool['desc'] as String,
                icon: tool['icon'] as IconData,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PdfToolPage(
                        title: tool['name'] as String,
                        description: tool['desc'] as String,
                        icon: tool['icon'] as IconData,
                        baseColor: AppColors.primaryAccent,
                      ),
                    ),
                  );
                },
              ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
            },
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
     return Container(
       width: double.infinity,
       padding: const EdgeInsets.symmetric(vertical: 60),
       decoration: BoxDecoration(
         border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.1))),
       ),
       child: Column(
         children: [
           Text(
             '© 2026 DOCFORGE AI - EMPOWERING DOCUMENTS',
             style: TextStyle(color: AppColors.textMuted, fontSize: 12, letterSpacing: 2),
           ),
         ],
       ),
     );
  }
}

class UploadBox extends StatelessWidget {
  const UploadBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
            child: const Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Drag & Drop your file here',
            style: TextStyle(fontSize: 18, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          CustomButton(text: 'Select File', onPressed: () {}),
        ],
      ),
    );
  }
}
