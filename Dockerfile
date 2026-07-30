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

# 1. Write environment variables to the .env file
cat << ENV_EOF > /app/.env
DISCORD_TOKEN="$DISCORD_TOKEN"
BOT_TOKEN="$DISCORD_TOKEN"
WEBHOOK_URL="$WEBHOOK_URL"
CHAT_CHANNEL_ID="$CHAT_CHANNEL_ID"
CHAT_LOG_CHANNEL_ID="$CHAT_LOG_CHANNEL_ID"
ENV_EOF

echo ".env file generated successfully."

# 2. Ensure database tables exist by running an initialization check
echo "Initializing database tables..."
python3 -c "
import asyncio, os, sqlite3, sys
sys.path.append('/app')

# Find sqlite database file or create default
db_path = 'database.db'
for root, dirs, files in os.walk('/app'):
    for file in files:
        if file.endswith('.db'):
            db_path = os.path.join(root, file)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Create required tables if they don't exist
cursor.execute('''CREATE TABLE IF NOT EXISTS servers (server_name TEXT PRIMARY KEY)''')
cursor.execute('''CREATE TABLE IF NOT EXISTS economy_settings (setting_key TEXT PRIMARY KEY, setting_value TEXT)''')
cursor.execute('''CREATE TABLE IF NOT EXISTS kits (name TEXT PRIMARY KEY, description TEXT, price INTEGER, category TEXT)''')
cursor.execute('''CREATE TABLE IF NOT EXISTS cooldowns (user_id TEXT, action TEXT, expires_at TIMESTAMP)''')

conn.commit()
conn.close()
print('Database tables verified/created successfully.')
"

# 3. Start a lightweight background HTTP server to satisfy Render's port-binding health check
python3 -c "
import http.server, os
port = int(os.environ.get('PORT', 10000))
server = http.server.HTTPServer(('', port), http.server.SimpleHTTPRequestHandler)
server.serve_forever()
" &

echo "Launching Palbot application via native startup.py..."
echo "--------------------------------------------------------"

# 4. Execute the official repository startup script
exec python -u startup.py
EOF

RUN chmod +x /app/start.sh

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

CMD ["/app/start.sh"]
