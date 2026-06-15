class VoiceAppException(Exception):
    """Base exception for the Voice Flutter Application."""
    pass

class AIServiceError(VoiceAppException):
    """Exception raised for errors in AI services (Gemini, OpenAI)."""
    pass

class ConversionError(VoiceAppException):
    """Exception raised for file conversion errors."""
    pass

class AudioProcessingError(VoiceAppException):
    """Exception raised for audio transcription / Whisper errors."""
    pass
