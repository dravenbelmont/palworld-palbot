FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends git build-essential && rm -rf /var/lib/apt/lists/*

# Clone the Palbot repository
RUN git clone https://github.com/dkoz/palworld-palbot .

# Install Python requirements
RUN pip install --no-cache-dir -r requirements.txt

# Create an error-catching runner script to expose hidden tracebacks
RUN cat << 'EOF' > /app/run_bot.py
import sys
import traceback
import os

print("Loading environment variables...")
from dotenv import load_dotenv
load_dotenv()

print("Attempting to start Palbot...")
try:
    sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), 'src')))
    import main
except Exception as e:
    print("=" * 60)
    print("CRITICAL ERROR: Palbot crashed with an exception!")
    traceback.print_exc()
    print("=" * 60)
    sys.exit(1)
EOF

# Create the startup wrapper script
RUN cat << 'EOF' > /app/start.sh
#!/bin/sh
set -e

echo "--------------------------------------------------------"
echo "Starting Palbot container setup..."

# 1. Write environment variables to the .env file expected by the bot
cat << ENV_EOF > /app/.env
DISCORD_TOKEN="$DISCORD_TOKEN"
WEBHOOK_URL="$WEBHOOK_URL"
CHAT_CHANNEL_ID="$CHAT_CHANNEL_ID"
CHAT_LOG_CHANNEL_ID="$CHAT_LOG_CHANNEL_ID"
ENV_EOF

echo ".env file generated successfully."

# 2. Start a background HTTP server to satisfy Render's port-binding health check
python3 -c "
import http.server, os
port = int(os.environ.get('PORT', 10000))
server = http.server.HTTPServer(('', port), http.server.SimpleHTTPRequestHandler)
server.serve_forever()
" &

echo "Launching Palbot with error tracking..."
echo "--------------------------------------------------------"

# 3. Run the error-catching wrapper script in the foreground
exec python -u /app/run_bot.py
EOF

RUN chmod +x /app/start.sh

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

CMD ["/app/start.sh"]
