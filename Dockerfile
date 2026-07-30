FROM python:3.12-slim

WORKDIR /app

# Install git and build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends git build-essential && rm -rf /var/lib/apt/lists/*

# Clone the Palbot repository
RUN git clone https://github.com/dkoz/palworld-palbot .

# Install the required Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create a robust runtime startup script with token validation and unbuffered logging
RUN cat << 'EOF' > /app/start.sh
#!/bin/sh

echo "--------------------------------------------------------"
echo "Starting Palbot container setup..."

# Validate that DISCORD_TOKEN is provided and isn't a placeholder
if [ -z "$DISCORD_TOKEN" ] || [ "$DISCORD_TOKEN" = "your_discord_bot_token_here" ]; then
    echo "CRITICAL ERROR: DISCORD_TOKEN is missing, empty, or set to a placeholder!"
    echo "Please configure a valid DISCORD_TOKEN in your Render Environment variables."
    exit 1
fi

# 1. Generate the .env file from Render runtime environment variables
cat << ENV_EOF > /app/.env
DISCORD_TOKEN="$DISCORD_TOKEN"
WEBHOOK_URL="$WEBHOOK_URL"
CHAT_CHANNEL_ID="$CHAT_CHANNEL_ID"
CHAT_LOG_CHANNEL_ID="$CHAT_LOG_CHANNEL_ID"
ENV_EOF

echo ".env file generated successfully."

# 2. Start a background dummy HTTP server to satisfy Render's port-binding requirement
python -c "
import http.server, os
port = int(os.environ.get('PORT', 10000))
server = http.server.HTTPServer(('', port), http.server.SimpleHTTPRequestHandler)
server.serve_forever()
" &

echo "Launching Palbot application..."
echo "--------------------------------------------------------"

# 3. Execute the bot application with unbuffered python output to capture crashes
exec python -u src/main.py
EOF

RUN chmod +x /app/start.sh

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

CMD ["/app/start.sh"]
