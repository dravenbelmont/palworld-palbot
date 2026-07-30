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

# 2. Automatically patch src/utils/database.py to guarantee table creation on every connection
echo "Injecting automatic database table initialization patch..."
python3 -c "
db_path = '/app/src/utils/database.py'
with open(db_path, 'r') as f:
    content = f.read()

patch_code = '''
import aiosqlite as _aiosqlite
_orig_connect = _aiosqlite.connect
async def _patched_connect(*args, **kwargs):
    db = await _orig_connect(*args, **kwargs)
    try:
        await db.execute(\"CREATE TABLE IF NOT EXISTS servers (server_name TEXT PRIMARY KEY)\")
        await db.execute(\"CREATE TABLE IF NOT EXISTS economy_settings (setting_key TEXT PRIMARY KEY, setting_value TEXT)\")
        await db.execute(\"CREATE TABLE IF NOT EXISTS kits (name TEXT PRIMARY KEY, description TEXT, price INTEGER, category TEXT)\")
        await db.execute(\"CREATE TABLE IF NOT EXISTS cooldowns (user_id TEXT, action TEXT, expires_at TIMESTAMP)\")
        await db.execute(\"CREATE TABLE IF NOT EXISTS players (steam_id TEXT, player_uid TEXT, name TEXT, server_name TEXT)\")
        await db.commit()
    except Exception as e:
        print(f'Auto-table creation error: {e}')
    return db
_aiosqlite.connect = _patched_connect
'''

if '_patched_connect' not in content:
    with open(db_path, 'w') as f:
        f.write(patch_code + '\n' + content)
    print('Successfully patched src/utils/database.py')
else:
    print('Database patch already applied.')
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
