import os
import pathlib
import subprocess
import sys

print("--------------------------------------------------------")
print("Starting Palbot container setup...")

env_path = pathlib.Path("/app/.env")

# Pull core configuration from Render environment variables with defaults
bot_token = os.getenv("BOT_TOKEN", "")
bot_prefix = os.getenv("BOT_PREFIX", "!")
bot_activity = os.getenv("BOT_ACTIVITY", "Palworld")
bot_language = os.getenv("BOT_LANGUAGE", "en")

# Support multiple naming conventions for chat and webhooks to prevent missing variable errors
chat_log_channel_id = (
    os.getenv("CHAT_LOG_CHANNEL_ID")
    or os.getenv("DISCORD_CHANNEL_ID")
    or os.getenv("CHANNEL_ID", "")
)
discord_webhook_url = (
    os.getenv("DISCORD_WEBHOOK_URL")
    or os.getenv("DISCORD_WEBHOOK")
    or os.getenv("WEBHOOK_URL", "")
)

# Pull RCON/Server settings
server_ip = os.getenv("SERVER_IP", "")
rcon_port = os.getenv("RCON_PORT", "25575")
rcon_password = os.getenv("RCON_PASSWORD", "")

# Write out the full environment file dynamically for the bot
env_content = f"""BOT_TOKEN={bot_token}
BOT_PREFIX={bot_prefix}
BOT_ACTIVITY={bot_activity}
BOT_LANGUAGE={bot_language}
CHAT_LOG_CHANNEL_ID={chat_log_channel_id}
DISCORD_CHANNEL_ID={chat_log_channel_id}
DISCORD_WEBHOOK_URL={discord_webhook_url}
DISCORD_WEBHOOK={discord_webhook_url}
SERVER_IP={server_ip}
RCON_PORT={rcon_port}
RCON_PASSWORD={rcon_password}
"""

env_path.write_text(env_content)
print(".env file generated successfully with chat and RCON configuration.")
print("--------------------------------------------------------")

# Launch the main application
main_script = "/app/src/main.py"
if not os.path.exists(main_script):
    main_script = "src/main.py"

subprocess.run([sys.executable, main_script])
