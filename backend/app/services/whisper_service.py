import os
import tempfile
import whisper
import asyncio
from typing import Optional

class WhisperService:
    _model = None

    @classmethod
    def get_model(cls):
        """Loads and returns the Whisper model, caching it after the first load."""
        if cls._model is None:
            print("Loading Whisper model... (this may take a minute on first run)")
            cls._model = whisper.load_model("base")
            print("Whisper model loaded successfully!")
        return cls._model

    @classmethod
    def transcribe_file(cls, file_path: str, initial_prompt: Optional[str] = None) -> str:
        """Transcribe a local audio file using Whisper."""
        model = cls.get_model()
        if initial_prompt is None:
            initial_prompt = "The following is a clear conversation in English, Hindi, or Telugu. Please transcribe it accurately with correct punctuation and spelling."
        
        result = model.transcribe(file_path, initial_prompt=initial_prompt)
        return result.get("text", "").strip()

    @classmethod
    def transcribe_bytes(cls, audio_bytes: bytes, suffix: str = ".webm", initial_prompt: Optional[str] = None) -> str:
        """Transcribe in-memory audio bytes by writing them to a temporary file."""
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as temp_audio:
            temp_audio.write(audio_bytes)
            temp_audio_path = temp_audio.name

        try:
            text = cls.transcribe_file(temp_audio_path, initial_prompt=initial_prompt)
            return text
        finally:
            if os.path.exists(temp_audio_path):
                os.unlink(temp_audio_path)
