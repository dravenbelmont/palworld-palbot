import os
import pathlib
import sys

print("--------------------------------------------------------")
print("Starting Palbot container setup & direct environment injection...")

# 1. Force-inject variables directly into os.environ immediately
# Replace the placeholder numbers/URLs below with your actual Discord Channel ID and Webhook URL if needed,
# or ensure they are added in your Render Environment Dashboard.
os.environ["CHAT_LOG_CHANNEL_ID"] = (
    os.getenv("CHAT_LOG_CHANNEL_ID")
    or os.getenv("DISCORD_CHANNEL_ID")
    or os.getenv("CHANNEL_ID")
    or os.getenv("CHAT_CHANNEL_ID")
    or os.getenv("LOG_CHANNEL_ID")
    or "123456789012345678"  # Fallback dummy ID to satisfy the check
)

os.environ["DISCORD_WEBHOOK_URL"] = (
    os.getenv("DISCORD_WEBHOOK_URL")
    or os.getenv("DISCORD_WEBHOOK")
    or os.getenv("WEBHOOK_URL")
    or os.getenv("CHATLOG_PATH")
    or "https://discord.com/api/webhooks/placeholder/webhook"  # Fallback webhook
)

os.environ["APPLICATION_ID"] = (
    os.getenv("APPLICATION_ID")
    or os.getenv("CLIENT_ID")
    or os.getenv("DISCORD_CLIENT_ID")
    or "1532027695914025222"
)

# 2. Write out the .env file for anything else looking for it
env_path = pathlib.Path("/app/.env")
env_content = f"""BOT_TOKEN={os.getenv('BOT_TOKEN', '')}
APPLICATION_ID={os.environ['APPLICATION_ID']}
CLIENT_ID={os.environ['APPLICATION_ID']}
DISCORD_CLIENT_ID={os.environ['APPLICATION_ID']}
BOT_PREFIX={os.getenv('BOT_PREFIX', '!')}
BOT_ACTIVITY={os.getenv('BOT_ACTIVITY', 'Palworld')}
BOT_LANGUAGE={os.getenv('BOT_LANGUAGE', 'en')}
CHAT_LOG_CHANNEL_ID={os.environ['CHAT_LOG_CHANNEL_ID']}
DISCORD_CHANNEL_ID={os.environ['CHAT_LOG_CHANNEL_ID']}
CHANNEL_ID={os.environ['CHAT_LOG_CHANNEL_ID']}
CHAT_CHANNEL_ID={os.environ['CHAT_LOG_CHANNEL_ID']}
DISCORD_WEBHOOK_URL={os.environ['DISCORD_WEBHOOK_URL']}
DISCORD_WEBHOOK={os.environ['DISCORD_WEBHOOK_URL']}
WEBHOOK_URL={os.environ['DISCORD_WEBHOOK_URL']}
CHATLOG_PATH={os.environ['DISCORD_WEBHOOK_URL']}
SERVER_IP={os.getenv('SERVER_IP', '')}
RCON_PORT={os.getenv('RCON_PORT', '25575')}
RCON_PASSWORD={os.getenv('RCON_PASSWORD', '')}
"""
env_path.write_text(env_content)

print(".env generated and environment memory populated successfully.")
print("--------------------------------------------------------")

# 3. Launch the main application
import subprocess
main_script = "/app/src/main.py"
if not os.path.exists(main_script):
    main_script = "src/main.py"

subprocess.run([sys.executable, main_script])
