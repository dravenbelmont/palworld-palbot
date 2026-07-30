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

# 2. Initialize database tables using the exact DATABASE_PATH from the app's code
echo "Initializing database tables using app's DATABASE_PATH..."
python3 -c "
import sys
sys.path.append('/app')
try:
    from src.utils.database import DATABASE_PATH
    import sqlite3, os
    
    print(f'Target database path from app: {DATABASE_PATH}')
    db_dir = os.path.dirname(DATABASE_PATH)
    if db_dir:
        os.makedirs(db_dir, exist_ok=True)
        
    conn = sqlite3.connect(DATABASE_PATH)
    cursor = conn.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS servers (server_name TEXT PRIMARY KEY)''')
    cursor.execute('''CREATE TABLE IF NOT EXISTS economy_settings (setting_key TEXT PRIMARY KEY, setting_value TEXT)''')
    cursor.execute('''CREATE TABLE IF NOT EXISTS kits (name TEXT PRIMARY KEY, description TEXT, price INTEGER, category TEXT)''')
    cursor.execute('''CREATE TABLE IF NOT EXISTS cooldowns (user_id TEXT, action TEXT, expires_at TIMESTAMP)''')
    cursor.execute('''CREATE TABLE IF NOT EXISTS players (steam_id TEXT, player_uid TEXT, name TEXT, server_name TEXT)''')
    conn.commit()
    conn.close()
    print('Database tables created successfully at exact app path.')
except Exception as e:
    print(f'Error initializing database: {e}')
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
