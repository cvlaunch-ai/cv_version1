import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isOutlined) {
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: OutlinedButton(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: BorderSide(color: _isHovered ? AppColors.primaryAccent : AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            backgroundColor: _isHovered ? Colors.white.withOpacity(0.05) : Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(widget.text, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (_isHovered)
              BoxShadow(
                color: AppColors.primaryAccent.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: Text(widget.text, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}
