FROM python:3.12-slim

WORKDIR /app

# Install git and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends git build-essential && rm -rf /var/lib/apt/lists/*

# Clone the Palbot repository
RUN git clone https://github.com/dkoz/palworld-palbot .

# Install the required Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Append the dummy HTTP server to src/main.py
RUN echo "" >> src/main.py && \
    echo "import http.server, threading, os" >> src/main.py && \
    echo "def run_dotenv_and_server():" >> src/main.py && \
    echo "    import os" >> src/main.py && \
    echo "    with open('/app/.env', 'w') as f:" >> src/main.py && \
    echo "        for k in ['DISCORD_TOKEN', 'WEBHOOK_URL', 'CHAT_CHANNEL_ID', 'CHAT_LOG_CHANNEL_ID']:" >> src/main.py && \
    echo "            v = os.environ.get(k)" >> src/main.py && \
    echo "            if v: f.write(f'{k}={v}\\n')" >> src/main.py && \
    echo "    port = int(os.environ.get('PORT', 10000))" >> src/main.py && \
    echo "    httpd = http.server.HTTPServer(('', port), http.server.SimpleHTTPRequestHandler)" >> src/main.py && \
    echo "    httpd.serve_forever()" >> src/main.py && \
    echo "threading.Thread(target=run_dotenv_and_server, daemon=False).start()" >> src/main.py

ENV PYTHONPATH=/app

CMD ["python", "src/main.py"]
