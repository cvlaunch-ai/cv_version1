import 'package:flutter/material.dart';
import 'custom_button.dart';

class UploadBox extends StatelessWidget {
  final VoidCallback? onSelectFile;
  final Color baseColor;

  const UploadBox({
    super.key,
    this.onSelectFile,
    this.baseColor = const Color(0xFFFF4D4D),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDDDDDD),
          style: BorderStyle.solid,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 64, color: baseColor),
          const SizedBox(height: 16),
          const Text(
            'Drag & Drop your file here',
            style: TextStyle(fontSize: 18, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Select File', 
            onPressed: onSelectFile ?? () {},
          ),
        ],
      ),
    );
  }
}
