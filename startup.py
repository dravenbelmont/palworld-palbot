import os
import pathlib
import subprocess
import sys
from dotenv import load_dotenv

print("--------------------------------------------------------")
print("Starting Palbot container setup...")

env_path = pathlib.Path("/app/.env")

# Pull core configuration
bot_token = os.getenv("BOT_TOKEN", "")
bot_prefix = os.getenv("BOT_PREFIX", "!")
bot_activity = os.getenv("BOT_ACTIVITY", "Palworld")
bot_language = os.getenv("BOT_LANGUAGE", "en")

# Cast a wide net for chat channel ID variations
chat_channel = (
    os.getenv("CHAT_LOG_CHANNEL_ID")
    or os.getenv("DISCORD_CHANNEL_ID")
    or os.getenv("CHANNEL_ID")
    or os.getenv("CHAT_CHANNEL_ID")
    or os.getenv("LOG_CHANNEL_ID")
    or os.getenv("CHAT_CHANNEL")
    or os.getenv("LOG_CHANNEL", "")
)

# Cast a wide net for webhook/path variations
webhook_url = (
    os.getenv("DISCORD_WEBHOOK_URL")
    or os.getenv("DISCORD_WEBHOOK")
    or os.getenv("WEBHOOK_URL")
    or os.getenv("WEBHOOK")
    or os.getenv("CHATLOG_PATH")
    or os.getenv("LOG_WEBHOOK_URL")
    or os.getenv("LOG_WEBHOOK", "")
)

# Pull RCON/Server settings
server_ip = os.getenv("SERVER_IP", "")
rcon_port = os.getenv("RCON_PORT", "25575")
rcon_password = os.getenv("RCON_PASSWORD", "")

# Write out every variation to the .env file so the bot finds whichever one it's hardcoded for
env_content = f"""BOT_TOKEN={bot_token}
BOT_PREFIX={bot_prefix}
BOT_ACTIVITY={bot_activity}
BOT_LANGUAGE={bot_language}
CHAT_LOG_CHANNEL_ID={chat_channel}
DISCORD_CHANNEL_ID={chat_channel}
CHANNEL_ID={chat_channel}
CHAT_CHANNEL_ID={chat_channel}
DISCORD_WEBHOOK_URL={webhook_url}
DISCORD_WEBHOOK={webhook_url}
WEBHOOK_URL={webhook_url}
CHATLOG_PATH={webhook_url}
SERVER_IP={server_ip}
RCON_PORT={rcon_port}
RCON_PASSWORD={rcon_password}
"""

env_path.write_text(env_content)

# Force load the generated .env into os.environ so the running process catches it immediately
load_dotenv(env_path, override=True)

print(".env file generated and loaded successfully.")
print("--------------------------------------------------------")

# Launch the main application
main_script = "/app/src/main.py"
if not os.path.exists(main_script):
    main_script = "src/main.py"

subprocess.run([sys.executable, main_script])
