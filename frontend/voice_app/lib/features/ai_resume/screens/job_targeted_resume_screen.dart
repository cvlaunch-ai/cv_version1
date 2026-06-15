import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import '../../../theme/app_theme.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/utils/responsive.dart';

class JobTargetedResumeScreen extends StatefulWidget {
  const JobTargetedResumeScreen({super.key});

  @override
  State<JobTargetedResumeScreen> createState() => _JobTargetedResumeScreenState();
}

class _JobTargetedResumeScreenState extends State<JobTargetedResumeScreen> {
  final TextEditingController _infoController = TextEditingController();
  final TextEditingController _jdController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();
  
  bool _isLoading = false;
  bool _hasGenerated = false;
  String _resumePreview = "";
  int _activeTab = 0; // 0 = Inputs, 1 = Preview
  final String _baseUrl = 'http://127.0.0.1:8001';

  Future<void> _generateTargetedResume() async {
    final info = _infoController.text.trim();
    final jd = _jdController.text.trim();
    
    if (info.isEmpty || jd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in both your info and the Job Description")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasGenerated = false;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-targeted-resume'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'personal_info': info,
          'job_description': jd,
          'template_id': 'classic'
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result.containsKey('error')) {
           _showError(result['error']);
        } else {
          setState(() {
            _resumePreview = result['resume'] ?? "";
            _resultController.text = _resumePreview;
            _hasGenerated = true;
            _activeTab = 1;
          });
        }
      } else {
        _showError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      _showError("Connection error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _downloadResume() async {
    if (_resumePreview.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-resume-pdf'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': _resumePreview,
          'template_id': 'classic'
        }),
      );
      
      if (response.statusCode == 200) {
        final blob = html.Blob([response.bodyBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "targeted_resume.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      _showError("Download Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final bool isMob = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isMob ? "Job-Targeted Resume" : "AI Job-Targeted Resume",
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(isMob ? 16.0 : 24.0),
        child: isMob ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: _activeTab == 0
              ? SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle("Your Information & Experience", Icons.person),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: _buildInputField(
                          controller: _infoController,
                          hint: "Paste your existing resume text, or describe your experience, projects, and skills here...",
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle("Target Job Description", Icons.work),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: _buildInputField(
                          controller: _jdController,
                          hint: "Paste the job description you are targeting here...",
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          text: _isLoading ? "Crafting your Resume..." : "Generate Targeted Resume 🪄",
                          onPressed: () => _generateTargetedResume(),
                        ),
                      ),
                    ],
                  ),
                )
              : _buildPreviewSectionMobile(),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 0 ? AppColors.secondaryAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    "Inputs",
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _activeTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _activeTab == 1 ? AppColors.secondaryAccent : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _hasGenerated ? "Tailored Preview ✨" : "Preview",
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewSectionMobile() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (!_hasGenerated && !_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white.withOpacity(0.1), size: 64),
                  const SizedBox(height: 20),
                  Text(
                    "Your tailored resume will appear here",
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
                  ),
                ],
              ),
            ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
          if (_hasGenerated && !_isLoading)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description, color: AppColors.primaryAccent, size: 20),
                      SizedBox(width: 12),
                      Text("Resume Preview", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TextField(
                      controller: _resultController,
                      maxLines: null,
                      readOnly: false,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => _resumePreview = val,
                    ),
                  ),
                ],
              ),
            ),
          if (_hasGenerated && !_isLoading)
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                onPressed: () => _downloadResume(),
                icon: const Icon(Icons.download_for_offline, color: AppColors.primaryAccent, size: 28),
                tooltip: "Download PDF",
              ).animate().fadeIn().slideX(begin: 0.5, end: 0),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Side: Inputs
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Your Information & Experience", Icons.person),
              const SizedBox(height: 12),
              Expanded(
                child: _buildInputField(
                  controller: _infoController,
                  hint: "Paste your existing resume text, or describe your experience, projects, and skills here...",
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle("Target Job Description", Icons.work),
              const SizedBox(height: 12),
              Expanded(
                child: _buildInputField(
                  controller: _jdController,
                  hint: "Paste the job description you are targeting here...",
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isLoading ? "Crafting your Resume..." : "Generate Targeted Resume 🪄",
                  onPressed: () => _generateTargetedResume(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Right Side: Preview
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0F1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                if (!_hasGenerated && !_isLoading)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.white.withOpacity(0.1), size: 64),
                        const SizedBox(height: 20),
                        Text(
                          "Your tailored resume will appear here",
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: AppColors.primaryAccent)),
                if (_hasGenerated && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.description, color: AppColors.primaryAccent, size: 24),
                            SizedBox(width: 12),
                            Text("Resume Preview", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Expanded(
                          child: TextField(
                            controller: _resultController,
                            maxLines: null,
                            readOnly: false,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              fontFamily: 'monospace',
                              height: 1.5,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                            ),
                            onChanged: (val) => _resumePreview = val,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_hasGenerated && !_isLoading)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      onPressed: () => _downloadResume(),
                      icon: const Icon(Icons.download_for_offline, color: AppColors.primaryAccent, size: 28),
                      tooltip: "Download PDF",
                    ).animate().fadeIn().slideX(begin: 0.5, end: 0),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryAccent, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String hint}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
