import shutil
import os

font_dir = "d:/voice_flutter/voice/voice_app/assets/fonts"
os.makedirs(font_dir, exist_ok=True)

# We don't have internet access to download, but we should check if we can simulate or if the user has it.
# Wait, the user provided instructions. I need to register it in pubspec.yaml.
# I will assume the user or I need to put a font file there.
# Since I cannot browse the web to download "NotoSans-Regular.ttf", I will check if I can use a system font or if there is one available.
# Actually, I CANNOT download files. I will create the directory and update pubspec.yaml. 
# I will also check if I can find any .ttf file to use as a placeholder or if I should ask the user to provide it.
# However, usually there might be a default font I can use. 
# For now I will proceed with updating pubspec.yaml and main.dart as requested.

print(f"Created directory: {font_dir}")
