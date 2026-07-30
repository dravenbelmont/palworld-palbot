FROM python:3.12-slim

WORKDIR /app

# Install git and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends git build-essential && rm -rf /var/lib/apt/lists/*

# Clone the Palbot repository
RUN git clone https://github.com/dkoz/palworld-palbot .

# Install the required Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Append the dummy HTTP server to src/main.py to satisfy Render's port requirement
RUN echo "" >> src/main.py && \
    echo "import http.server, threading, os" >> src/main.py && \
    echo "def run_dummy_server():" >> src/main.py && \
    echo "    port = int(os.environ.get('PORT', 10000))" >> src/main.py && \
    echo "    httpd = http.server.HTTPServer(('', port), http.server.SimpleHTTPRequestHandler)" >> src/main.py && \
    echo "    httpd.serve_forever()" >> src/main.py && \
    echo "threading.Thread(target=run_dummy_server, daemon=false).start()" >> src/main.py

# Create a startup wrapper script that generates the .env file from Render environment variables at runtime
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'cp /app/.env.example /app/.env 2>/dev/null || true' >> /app/start.sh && \
    echo 'echo "DISCORD_TOKEN=$DISCORD_TOKEN" >> /app/.env' >> /app/start.sh && \
    echo 'echo "WEBHOOK_URL=$WEBHOOK_URL" >> /app/.env' >> /app/start.sh && \
    echo 'echo "CHAT_CHANNEL_ID=$CHAT_CHANNEL_ID" >> /app/.env' >> /app/start.sh && \
    echo 'echo "CHAT_LOG_CHANNEL_ID=$CHAT_LOG_CHANNEL_ID" >> /app/.env' >> /app/start.sh && \
    echo 'exec python src/main.py' >> /app/start.sh && \
    chmod +x /app/start.sh

ENV PYTHONPATH=/app

CMD ["/app/start.sh"]
