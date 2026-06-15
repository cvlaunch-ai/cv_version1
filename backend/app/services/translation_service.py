from deep_translator import GoogleTranslator

class TranslationService:
    @staticmethod
    def translate_to_english(text: str) -> str:
        """Translate text to English if it's in another language."""
        try:
            # Force translate to 'en' from 'auto'
            translator = GoogleTranslator(source='auto', target='en')
            translated = translator.translate(text)
            return translated
        except Exception as e:
            print(f"Translation Error: {e}")
            return text
