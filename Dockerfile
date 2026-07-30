FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends git build-essential && rm -rf /var/lib/apt/lists/*

# Clone the Palbot repository
RUN git clone https://github.com/dkoz/palworld-palbot .

# Install Python requirements
RUN pip install --no-cache-dir -r requirements.txt

# Create the Render wrapper script
RUN cat << 'EOF' > /app/start.sh
#!/bin/sh
set -e

echo "--------------------------------------------------------"
echo "Starting Palbot container setup..."

# 1. Write environment variables to the .env file expected by startup.py
cat << ENV_EOF > /app/.env
DISCORD_TOKEN="$DISCORD_TOKEN"
WEBHOOK_URL="$WEBHOOK_URL"
CHAT_CHANNEL_ID="$CHAT_CHANNEL_ID"
CHAT_LOG_CHANNEL_ID="$CHAT_LOG_CHANNEL_ID"
ENV_EOF

echo ".env file generated successfully."

# 2. Start a lightweight background HTTP server to satisfy Render's port-binding health check
python3 -c "
import http.server, os
port = int(os.environ.get('PORT', 10000))
server = http.server.HTTPServer(('', port), http.server.SimpleHTTPRequestHandler)
server.serve_forever()
" &

echo "Launching Palbot application via native startup.py..."
echo "--------------------------------------------------------"

# 3. Execute the official repository startup script
exec python -u startup.py
EOF

RUN chmod +x /app/start.sh

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

CMD ["/app/start.sh"]
