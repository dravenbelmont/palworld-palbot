import os
import pathlib
import subprocess
import sys
from dotenv import load_dotenv

print("--------------------------------------------------------")
print("Starting Palbot container setup & configuration fix...")

env_path = pathlib.Path("/app/.env")

# Core configurations
bot_token = os.getenv("BOT_TOKEN", "")
bot_prefix = os.getenv("BOT_PREFIX", "!")
bot_activity = os.getenv("BOT_ACTIVITY", "Palworld")
bot_language = os.getenv("BOT_LANGUAGE", "en")

# Capture Application ID / Client ID to fix the 'None' API spam error
application_id = (
    os.getenv("APPLICATION_ID")
    or os.getenv("CLIENT_ID")
    or os.getenv("DISCORD_CLIENT_ID", "1532027695914025222")
)

# Catch-all environment variables for chat and webhooks
chat_channel = (
    os.getenv("CHAT_LOG_CHANNEL_ID")
    or os.getenv("DISCORD_CHANNEL_ID")
    or os.getenv("CHANNEL_ID")
    or os.getenv("CHAT_CHANNEL_ID")
    or os.getenv("LOG_CHANNEL_ID")
    or "0"
)

webhook_url = (
    os.getenv("DISCORD_WEBHOOK_URL")
    or os.getenv("DISCORD_WEBHOOK")
    or os.getenv("WEBHOOK_URL")
    or os.getenv("CHATLOG_PATH")
    or "https://placeholder.webhook"
)

server_ip = os.getenv("SERVER_IP", "")
rcon_port = os.getenv("RCON_PORT", "25575")
rcon_password = os.getenv("RCON_PASSWORD", "")

# Write comprehensive .env containing every key name variant including Application ID
env_content = f"""BOT_TOKEN={bot_token}
APPLICATION_ID={application_id}
CLIENT_ID={application_id}
DISCORD_CLIENT_ID={application_id}
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
load_dotenv(env_path, override=True)

print(".env generated and loaded with Application ID successfully.")
print("--------------------------------------------------------")

# Launch the main application
main_script = "/app/src/main.py"
if not os.path.exists(main_script):
    main_script = "src/main.py"

subprocess.run([sys.executable, main_script])
