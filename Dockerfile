FROM python:3.12-slim

WORKDIR /app

# Install git and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends git build-essential && rm -rf /var/lib/apt/lists/*

# Clone the Palbot repository
RUN git clone https://github.com/dkoz/palworld-palbot .

# Install the required Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Append the dummy HTTP server and .env generator safely via EOF block
RUN cat << 'EOF' >> src/main.py

import http.server
import threading
import os

def run_dotenv_and_server():
    with open('/app/.env', 'w') as f:
        for k in ['DISCORD_TOKEN', 'WEBHOOK_URL', 'CHAT_CHANNEL_ID', 'CHAT_LOG_CHANNEL_ID']:
            v = os.environ.get(k)
            if v:
                f.write(f"{k}={v}\n")
                
    port = int(os.environ.get('PORT', 10000))
    httpd = http.server.HTTPServer(('', port), http.server.SimpleHTTPRequestHandler)
    httpd.serve_forever()

threading.Thread(target=run_dotenv_and_server, daemon=False).start()
EOF

ENV PYTHONPATH=/app

CMD ["python", "src/main.py"]
