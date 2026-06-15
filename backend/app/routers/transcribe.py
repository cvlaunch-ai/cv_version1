import os
import tempfile
import asyncio
from fastapi import APIRouter, UploadFile, File, WebSocket
from websockets.exceptions import ConnectionClosedOK
from app.services.whisper_service import WhisperService

router = APIRouter()

@router.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)):
    try:
        audio_bytes = await file.read()
        print(f"Received audio: {len(audio_bytes)} bytes")
        
        # Transcribe with WhisperService
        text = WhisperService.transcribe_bytes(audio_bytes, suffix=".webm")
        print(f"Result: {text}")
        
        return {"text": text}
    
    except Exception as e:
        print(f"Error: {e}")
        return {"text": f"[ERROR] {str(e)}"}

@router.websocket("/ws/transcribe")
async def ws_transcribe(websocket: WebSocket):
    """
    Client sends raw audio bytes (webm) in chunks.
    Server runs Whisper on the accumulated audio and sends
    interim text back after each chunk.
    """
    await websocket.accept()
    audio_buffer = bytearray()
    last_chunk_time = asyncio.get_event_loop().time()

    try:
        async for message in websocket:
            if isinstance(message, bytes):
                audio_buffer.extend(message)
                now = asyncio.get_event_loop().time()
                if now - last_chunk_time > 1.5:
                    if len(audio_buffer) > 0:
                        with tempfile.NamedTemporaryFile(delete=False, suffix=".webm") as tmp:
                            tmp.write(audio_buffer)
                            tmp_path = tmp.name

                        try:
                            prompt = "The following is a clear conversation. Please transcribe it accurately."
                            text = WhisperService.transcribe_file(tmp_path, initial_prompt=prompt)
                            if text:
                                await websocket.send_text(text)
                        except Exception as e:
                            print(f"Transcription error: {e}")
                        finally:
                            if os.path.exists(tmp_path):
                                os.unlink(tmp_path)
                        
                        audio_buffer.clear()
                last_chunk_time = now
            else:
                continue
    except ConnectionClosedOK:
        print("WebSocket closed normally")
    except Exception as e:
        print(f"WebSocket error: {e}")
