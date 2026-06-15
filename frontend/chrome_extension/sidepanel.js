let recognition;
let isRecording = false;
let wordCount = 0;
let autoRestartTimeout;

// Initialize Speech Recognition
if ('webkitSpeechRecognition' in window) {
    recognition = new webkitSpeechRecognition();
    recognition.continuous = true;
    recognition.interimResults = true;
    recognition.lang = document.getElementById('languageSelect').value || 'en-US';
    recognition.maxAlternatives = 1;

    recognition.onstart = () => {
        isRecording = true;
        updateUI(true);
    };

    recognition.onend = () => {
        // Auto-restart if still in recording mode to prevent timeout
        if (isRecording) {
            console.log('Recognition ended, restarting for continuous listening...');
            clearTimeout(autoRestartTimeout);
            autoRestartTimeout = setTimeout(() => {
                try {
                    recognition.start();
                } catch (e) {
                    console.log('Recognition restart error:', e);
                }
            }, 100);
        } else {
            isRecording = false;
            updateUI(false);
        }
    };

    recognition.onresult = (event) => {
        let finalTranscript = '';
        let interimTranscript = '';

        for (let i = event.resultIndex; i < event.results.length; i++) {
            const transcript = event.results[i][0].transcript;
            if (event.results[i].isFinal) {
                finalTranscript += transcript + ' ';
            } else {
                interimTranscript += transcript;
            }
        }

        const output = document.getElementById('output');

        // If we have final text, append it permanently
        if (finalTranscript) {
            // Remove any previous interim text span if it exists
            const interimSpan = document.getElementById('interim');
            if (interimSpan) interimSpan.remove();

            output.innerHTML += finalTranscript;

            // Update word count for display only
            updateWordCount();
        }

        // If we have interim text, show it in a grayed-out span
        if (interimTranscript) {
            const interimSpan = document.getElementById('interim');
            if (interimSpan) {
                interimSpan.textContent = interimTranscript;
            } else {
                output.innerHTML += `<span id="interim" style="color: #888;">${interimTranscript}</span>`;
            }
        } else {
            // If no interim text, remove the span
            const interimSpan = document.getElementById('interim');
            if (interimSpan) interimSpan.remove();
        }

        // Scroll to bottom
        output.scrollTop = output.scrollHeight;
    };

    recognition.onerror = (event) => {
        console.error('Speech error:', event.error);
        document.getElementById('status').textContent = 'Error: ' + event.error;
        document.getElementById('status').title = 'Full error: ' + JSON.stringify(event);
        isRecording = false;
        updateUI(false);
    };
} else {
    document.getElementById('status').textContent = 'Speech recognition not supported';
}

// UI Functions
function updateUI(recording) {
    const btn = document.getElementById('micBtn');
    const status = document.getElementById('status');

    if (recording) {
        btn.classList.add('recording');
        status.classList.add('recording');
        status.textContent = `Listening... (${wordCount} words)`;
        status.style.background = '';
        status.style.color = '';
    } else {
        btn.classList.remove('recording');
        status.classList.remove('recording');
        status.textContent = `Ready to record (${wordCount} words)`;
        status.style.background = '';
        status.style.color = '';
    }
}

// Word count function
function updateWordCount() {
    const output = document.getElementById('output');
    const text = output.innerText.trim();
    wordCount = text ? text.split(/\s+/).filter(word => word.length > 0).length : 0;

    // Update badge
    const badge = document.getElementById('wordCountBadge');
    if (badge) {
        badge.textContent = `${wordCount} words`;
        badge.style.background = '#667eea'; // Always blue - unlimited
    }

    // Update UI with current count
    if (isRecording) {
        const status = document.getElementById('status');
        status.textContent = `Listening... (${wordCount} words)`;
    }
}

// Event Listeners
document.getElementById('micBtn').addEventListener('click', () => {
    if (!recognition) return;

    if (isRecording) {
        clearTimeout(autoRestartTimeout);
        recognition.stop();
        isRecording = false;
        updateUI(false);
    } else {
        // Update language before starting
        const lang = document.getElementById('languageSelect').value;
        recognition.lang = lang;
        recognition.start();
    }
});

// Language Change Listener
document.getElementById('languageSelect').addEventListener('change', () => {
    if (isRecording) {
        recognition.stop();
        setTimeout(() => {
            const lang = document.getElementById('languageSelect').value;
            recognition.lang = lang;
            recognition.start();
        }, 500); // Small delay to ensure clean stop
    }
});

// Helper functions attached to window for HTML onclick access
window.copyText = () => {
    const text = document.getElementById('output').innerText;
    navigator.clipboard.writeText(text).then(() => {
        const status = document.getElementById('status');
        const original = status.textContent;
        status.textContent = 'Copied to clipboard!';
        setTimeout(() => status.textContent = original, 2000);
    });
};

window.clearText = () => {
    document.getElementById('output').innerText = '';
    wordCount = 0;
    updateUI(isRecording);
};

window.saveToSheet = async () => {
    const text = document.getElementById('output').innerText;
    const status = document.getElementById('status');

    if (!text.trim()) {
        status.textContent = 'No text to save!';
        setTimeout(() => status.textContent = 'Ready to record', 2000);
        return;
    }

    status.textContent = 'Saving to Sheet...';

    try {
        const response = await fetch('http://127.0.0.1:8001/parse-and-save', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ text: text })
        });

        const result = await response.json();

        if (result.status && result.status.includes('Saved')) {
            status.textContent = '✅ Saved to Sheet!';
        } else {
            status.textContent = '❌ Save Failed: ' + (result.error || result.status);
        }
    } catch (error) {
        console.error('Save error:', error);
        status.textContent = '❌ Connection Error';
    }

    setTimeout(() => status.textContent = 'Ready to record', 3000);
};
