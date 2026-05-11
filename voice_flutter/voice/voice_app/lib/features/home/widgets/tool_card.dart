import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../theme/app_theme.dart';

class ToolCard extends StatefulWidget {
  final String name;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const ToolCard({
    super.key,
    required this.name,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.surface2 : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? AppColors.primaryAccent.withOpacity(0.5) : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: AppColors.primaryAccent.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ShaderMask(
                    shaderCallback: (bounds) => AppColors.primaryGradient.createShader(bounds),
                    child: Icon(
                      widget.icon,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                    overflow: TextOverflow.fade,
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate(target: _isHovered ? 1 : 0)
       .scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 200.ms),
    );
  }
}
