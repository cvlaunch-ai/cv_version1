import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../shared/widgets/custom_button.dart';
import '../widgets/tool_card.dart';
import '../../pdf_tools/tools/merge_pdf.dart';
import '../../pdf_tools/tools/split_pdf.dart';
import '../../pdf_tools/tools/compress_pdf.dart';
import '../../pdf_tools/tools/pdf_to_word.dart';
import '../../pdf_tools/tools/pdf_to_excel.dart';
import '../../pdf_tools/tools/word_to_pdf.dart';
import '../../pdf_tools/tools/powerpoint_to_pdf.dart';
import '../../pdf_tools/tools/excel_to_pdf.dart';
import '../../ai_resume/screens/resume_generator_screen.dart';
import '../../ai_resume/screens/job_targeted_resume_screen.dart';
import '../../ai_resume/screens/cover_letter_generator_screen.dart';
import '../../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final bool useDrawer = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(useDrawer),
      drawer: useDrawer ? _buildDrawer() : null,
      body: Stack(
        children: [
          // Background Gradient Glow
          Positioned(
            top: -200,
            right: -200,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryAccent.withOpacity(0.05),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 5.seconds)
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

  PreferredSizeWidget _buildAppBar(bool useDrawer) {
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
      actions: useDrawer
          ? [
              IconButton(
                icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              const SizedBox(width: 16),
            ]
          : [
              CustomButton(
                text: 'AI Resume',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ResumeGeneratorScreen()));
                },
                isOutlined: true,
              ),
              const SizedBox(width: 12),
              CustomButton(
                text: 'AI Targeted Resume',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const JobTargetedResumeScreen()));
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

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.background,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: AppColors.border.withOpacity(0.1)),
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border.withOpacity(0.1)),
                ),
              ),
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                    child: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'DOCFORGE AI',
                    style: AppTheme.logoStyle.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildDrawerItem(
              icon: Icons.description,
              title: 'AI Resume',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ResumeGeneratorScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildDrawerItem(
              icon: Icons.track_changes,
              title: 'AI Targeted Resume',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const JobTargetedResumeScreen()));
              },
            ),
            const SizedBox(height: 12),
            _buildDrawerItem(
              icon: Icons.edit_document,
              title: 'AI Cover Letter',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CoverLetterGeneratorScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryAccent),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        hoverColor: Colors.white.withOpacity(0.05),
        onTap: onTap,
      ),
    );
  }

  Widget _buildHeroSection() {
    final double width = MediaQuery.of(context).size.width;
    final double paddingVal = width < 600 ? 16.0 : 24.0;
    final double verticalPadding = width < 600 ? 60.0 : (width < 1024 ? 80.0 : 100.0);
    final double headlineSize = width < 600 ? 32.0 : (width < 1024 ? 40.0 : 48.0);
    final double descSize = width < 600 ? 14.0 : (width < 1024 ? 16.0 : 18.0);

    return Container(
      padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: paddingVal),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
            child: Text(
              'The Future of Document Intelligence',
              textAlign: TextAlign.center,
              style: AppTheme.headlineStyle.copyWith(fontSize: headlineSize, color: Colors.white),
            ),
          ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 24),
          Text(
            'DocForge AI combines advanced PDF tools with neural intelligence to transform how you work.\nFast, secure, and powered by the next generation of web design.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: descSize,
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
      {'name': 'Merge PDF', 'desc': 'Combine multiple PDFs into one seamless document.', 'icon': Icons.call_merge, 'screen': const MergePdfTool()},
      {'name': 'Split PDF', 'desc': 'Extract pages or split your PDF into separate files.', 'icon': Icons.call_split, 'screen': const SplitPdfTool()},
      {'name': 'Compress PDF', 'desc': 'Optimize size without sacrificing quality.', 'icon': Icons.compress, 'screen': const CompressPdfTool()},
      {'name': 'PDF to Word', 'desc': 'Convert PDFs to editable Word documents instantly.', 'icon': Icons.description, 'screen': const PdfToWordTool()},
      {'name': 'PDF to Excel', 'desc': 'Extract data from PDFs into structured spreadsheets.', 'icon': Icons.table_chart, 'screen': const PdfToExcelTool()},
      {'name': 'Word to PDF', 'desc': 'Professional Word to PDF conversion.', 'icon': Icons.picture_as_pdf, 'screen': const WordToPdfTool()},
      {'name': 'PPT to PDF', 'desc': 'Transform presentations into shared PDFs.', 'icon': Icons.slideshow, 'screen': const PowerPointToPdfTool()},
      {'name': 'Excel to PDF', 'desc': 'Convert spreadsheets into readable PDFs.', 'icon': Icons.grid_on, 'screen': const ExcelToPdfTool()},
    ];

    final double width = MediaQuery.of(context).size.width;
    final double paddingVal = width < 600 ? 16.0 : 40.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: paddingVal),
      constraints: const BoxConstraints(maxWidth: 1400),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 600 ? 2 : 1));
          double childAspectRatio = constraints.maxWidth > 1200 ? 0.9 : (constraints.maxWidth > 800 ? 1.0 : (constraints.maxWidth > 600 ? 1.0 : 1.3));
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              childAspectRatio: childAspectRatio,
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
                      builder: (context) => tool['screen'] as Widget,
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
      child: const Column(
        children: [
          Text(
            '© 2026 DOCFORGE AI - PREMIUM DOCUMENT SOLUTIONS',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12, letterSpacing: 2),
          ),
        ],
      ),
    );
  }
}
