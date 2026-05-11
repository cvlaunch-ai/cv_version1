# 🎤 Voice to Text App - OpenAI Whisper Integration

A complete Flutter + Python FastAPI application for converting voice recordings to text using OpenAI's Whisper API.

## 📁 Project Structure

```
voice/
├── whisper_backend/          # Python FastAPI backend
│   ├── main.py              # FastAPI server with Whisper integration
│   ├── requirements.txt     # Python dependencies
│   └── venv/                # Virtual environment
└── voice_app/               # Flutter mobile app
    ├── lib/
    │   ├── main.dart        # App entry point
    │   └── voice_to_text.dart  # Voice recording & transcription UI
    └── pubspec.yaml         # Flutter dependencies
```

## 🚀 Setup Instructions

### Backend Setup (Python)

1. **Navigate to backend folder:**
   ```bash
   cd whisper_backend
   ```

2. **Activate virtual environment:**
   ```bash
   # Windows
   .\venv\Scripts\activate
   
   # Mac/Linux
   source venv/bin/activate
   ```

3. **Set your OpenAI API Key:**
   ```bash
   # Windows PowerShell
   $env:OPENAI_API_KEY="sk-..."
   
   # Mac/Linux
   export OPENAI_API_KEY="sk-..."
   ```

4. **Run the backend:**
   ```bash
   uvicorn main:app --reload --port 8000
   ```

5. **Test the API:**
   - Open browser: http://127.0.0.1:8000/docs
   - You should see the FastAPI interactive documentation

### Flutter App Setup

1. **Navigate to Flutter app:**
   ```bash
   cd voice_app
   ```

2. **Install dependencies (already done):**
   ```bash
   flutter pub get
   ```

3. **Configure API endpoint:**
   - For Android Emulator: Uses `http://10.0.2.2:8000/transcribe` (already configured)
   - For Real Device: Edit `lib/voice_to_text.dart` line 57 and replace with your computer's IP:
     ```dart
     Uri.parse("http://YOUR_COMPUTER_IP:8000/transcribe")
     ```
     Example: `http://192.168.1.5:8000/transcribe`

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🎯 How to Use

1. **Start the backend** (make sure it's running!)
2. **Launch the Flutter app** on your device/emulator
3. **Tap "Start Recording"** - speak into your microphone
4. **Tap "Stop Recording"** when done
5. **Tap "Convert to Text"** - wait for processing
6. **View the transcribed text** in the output box!

## 🔧 Troubleshooting

### Backend Issues
- **"OPENAI_API_KEY not set"**: Make sure you set the environment variable before running uvicorn
- **Port already in use**: Change the port with `--port 8001`

### Flutter Issues
- **Connection refused**: 
  - Make sure backend is running
  - For real device, use your computer's IP address (not localhost)
  - Check firewall settings
- **Permission denied**: Grant microphone permission when prompted

### Finding Your Computer's IP Address
```bash
# Windows
ipconfig

# Mac/Linux
ifconfig
```
Look for your local IP (usually starts with 192.168.x.x)

## 📱 Features

✅ Voice recording with visual feedback
✅ Real-time recording status
✅ OpenAI Whisper transcription
✅ Clean, modern UI
✅ Error handling
✅ Loading states
✅ Cross-platform support (Android/iOS)

## 🎨 Next Steps (Optional Enhancements)

Want to add more features? Here are some ideas:

1. **Multi-language support** (Telugu, Hindi, etc.)
2. **Real-time streaming transcription**
3. **Save transcriptions to database** (Neon/PlanetScale)
4. **Transcription history**
5. **ChatGPT integration** (AI assistant from voice)
6. **Export transcriptions** (PDF, TXT)

## 📝 Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: FastAPI (Python)
- **AI**: OpenAI Whisper API
- **Audio**: flutter_sound package
- **Permissions**: permission_handler

## 🔑 Important Notes

- Keep your OpenAI API key secure (never commit to git!)
- Whisper API charges per minute of audio
- Requires internet connection for transcription
- Microphone permission required

---

Made with ❤️ using Flutter & OpenAI Whisper
