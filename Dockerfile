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

# 2. Force absolute database path and initialize/seed tables
python3 -c "
import os, sqlite3

db_path = '/app/data/palbot.db'
os.makedirs(os.path.dirname(db_path), exist_ok=True)

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Create all required tables
cursor.execute('''CREATE TABLE IF NOT EXISTS servers (server_name TEXT PRIMARY KEY)''')
cursor.execute('''CREATE TABLE IF NOT EXISTS economy_settings (setting_key TEXT PRIMARY KEY, setting_value TEXT)''')
cursor.execute('''CREATE TABLE IF NOT EXISTS kits (name TEXT PRIMARY KEY, description TEXT, price INTEGER, category TEXT)''')
cursor.execute('''CREATE TABLE IF NOT EXISTS cooldowns (user_id TEXT, action TEXT, expires_at TIMESTAMP)''')
cursor.execute('''CREATE TABLE IF NOT EXISTS players (steam_id TEXT, player_uid TEXT, name TEXT, server_name TEXT)''')

# Seed default economy settings to prevent NoneType casting errors
defaults = {
    'vote_reward': '10',
    'currency_name': 'points',
    'invite_reward': '10',
    'starting_balance': '0'
}
for k, v in defaults.items():
    cursor.execute('''INSERT OR IGNORE INTO economy_settings (setting_key, setting_value) VALUES (?, ?)''', (k, v))

conn.commit()
conn.close()
print('Absolute database path initialized and seeded successfully at:', db_path)
"

# 3. Patch src/utils/database.py to enforce absolute DATABASE_PATH and bulletproof get_economy_setting
python3 -c "
db_utils_path = '/app/src/utils/database.py'
with open(db_utils_path, 'r') as f:
    code = f.read()

# Enforce absolute path
code = code.replace('DATABASE_PATH = \"data/palbot.db\"', 'DATABASE_PATH = \"/app/data/palbot.db\"')
code = code.replace(\"DATABASE_PATH = 'data/palbot.db'\", \"DATABASE_PATH = '/app/data/palbot.db'\")

with open(db_utils_path, 'w') as f:
    f.write(code)

print('Patched database.py with absolute path.')
"

# 4. Start a lightweight background HTTP server to satisfy Render's port-binding health check
python3 -c "
import http.server, os
port = int(os.environ.get('PORT', 10000))
server = http.server.HTTPServer(('', port), http.server.SimpleHTTPRequestHandler)
server.serve_forever()
" &

echo "Launching Palbot application via native startup.py..."
echo "--------------------------------------------------------"

# 5. Execute the official repository startup script
exec python -u startup.py
EOF

RUN chmod +x /app/start.sh

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

CMD ["/app/start.sh"]
