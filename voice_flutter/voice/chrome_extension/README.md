# Voice to Text Chrome Extension

## Features
- 🎤 **Continuous Voice Recognition** - Extended listening time with auto-restart to prevent timeouts
- 📊 **Word Count Tracking** - Real-time word count display with visual feedback
- ⚠️ **Smart Limits** - Minimum 300 words, Maximum 500 words with color-coded warnings
- 🌍 **Multi-language Support** - Supports 11+ Indian languages plus English
- ✏️ **Editable Output** - Edit transcribed text before saving
- 💾 **Backend Integration** - Save parsed data to Excel/Google Sheets via FastAPI backend
- 🔄 **Auto-restart** - Automatically restarts recognition to ensure continuous listening

## Word Limit System
- **0-299 words**: Blue badge - Keep speaking
- **300-499 words**: Yellow badge - Approaching limit
- **500 words**: Red badge - Maximum reached, recording stops automatically

## Installation

### 1. Load the Extension in Chrome

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable **Developer mode** (toggle in top-right corner)
3. Click **Load unpacked**
4. Select the `chrome_extension` folder: `d:\voice_flutter\voice\chrome_extension`
5. The extension should now appear in your extensions list

### 2. Pin the Extension (Optional)

1. Click the puzzle piece icon (🧩) in Chrome toolbar
2. Find "Voice to Text" extension
3. Click the pin icon to keep it visible

### 3. Start the Backend Server

Before using the extension, make sure the FastAPI backend is running:

```powershell
cd d:\voice_flutter\voice\whisper_backend
python main.py
```

The backend should start on `http://127.0.0.1:8000`

## Usage

### Basic Recording

1. Click the extension icon or open the side panel
2. Select your preferred language from the dropdown
3. Click the 🎤 microphone button to start recording
4. Speak clearly - the extension will continuously listen and transcribe
5. Watch the word count badge to track your progress
6. Click the microphone button again to stop recording

### Features During Recording

- **Real-time Transcription**: See your words appear as you speak
- **Interim Results**: Gray text shows what's being processed
- **Word Count**: Live counter shows current words / 500 max
- **Auto-restart**: Recognition automatically restarts every ~60 seconds to prevent timeout
- **Language Switch**: Change language mid-recording (will restart recognition)

### After Recording

- **Edit**: Click in the text area to edit the transcribed text
- **Copy**: Click 📋 Copy to copy text to clipboard
- **Clear**: Click 🗑️ Clear to remove all text and reset counter
- **Save**: Click 💾 Save to Sheet to send data to backend for parsing and storage

## Supported Languages

- English (US)
- Hindi (हिन्दी)
- Bengali (বাংলা)
- Telugu (తెలుగు)
- Marathi (मराठी)
- Tamil (தமிழ்)
- Urdu (اردو)
- Gujarati (ગુજરાતી)
- Kannada (ಕನ್ನಡ)
- Malayalam (മലയാളം)
- Punjabi (ਪੰਜਾਬੀ)

## Technical Details

### Continuous Listening Implementation

The extension uses several techniques to ensure long-duration listening:

1. **continuous: true** - Enables continuous recognition mode
2. **Auto-restart on end** - Automatically restarts recognition when it stops
3. **100ms restart delay** - Brief pause between restarts to prevent errors
4. **Word limit check** - Only restarts if under 500 words

### Word Count Tracking

- Counts words in real-time after each final transcript
- Updates visual badge with color coding
- Enforces maximum limit by stopping recognition at 500 words
- Prevents new recording if already at max (must clear first)

## Troubleshooting

### Extension not loading
- Make sure you selected the correct folder containing `manifest.json`
- Check Chrome console for errors (F12)

### Microphone not working
- Grant microphone permissions when prompted
- Check Chrome settings: `chrome://settings/content/microphone`
- Ensure no other app is using the microphone

### Recognition stops too quickly
- The extension now auto-restarts every ~60 seconds
- Check console for restart messages
- If issues persist, try stopping and starting again

### Backend connection error
- Ensure FastAPI server is running on `http://127.0.0.1:8000`
- Check server logs for errors
- Verify CORS is enabled in backend

### Word count not updating
- Make sure you're seeing "final" text (not gray interim text)
- Try clicking in the text area to trigger an update
- Clear and restart if counter seems stuck

## Files

- `manifest.json` - Extension configuration
- `sidepanel.html` - User interface
- `sidepanel.js` - Speech recognition logic and word counting
- `README.md` - This file

## Backend Integration

The extension sends transcribed text to the backend at:
```
POST http://127.0.0.1:8000/parse-and-save
```

The backend:
1. Receives the text
2. Translates to English if needed
3. Parses fields (name, email, phone, job role)
4. Saves to Excel file (`leads_data.xlsx`)

## Updates Made

### Latest Changes (Current Version)
- ✅ Increased listening time with auto-restart mechanism
- ✅ Added 300-500 word limit enforcement
- ✅ Real-time word count display with color-coded badge
- ✅ Visual warnings when approaching/exceeding limits
- ✅ Improved continuous recognition reliability
- ✅ Added Save to Sheet button for easy backend integration
- ✅ Enhanced status messages with word count

## License

This extension is part of the voice_flutter project.
