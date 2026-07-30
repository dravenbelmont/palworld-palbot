import os
import pathlib
import json
import subprocess
import sys

print("--------------------------------------------------------")
print("Starting Palbot container setup & multi-config injection...")

# 1. Define fallbacks and capture actual environment variables
chat_channel = (
    os.getenv("CHAT_LOG_CHANNEL_ID")
    or os.getenv("DISCORD_CHANNEL_ID")
    or os.getenv("CHANNEL_ID")
    or os.getenv("CHAT_CHANNEL_ID")
    or os.getenv("LOG_CHANNEL_ID")
    or "123456789012345678"
)

webhook_url = (
    os.getenv("DISCORD_WEBHOOK_URL")
    or os.getenv("DISCORD_WEBHOOK")
    or os.getenv("WEBHOOK_URL")
    or os.getenv("CHATLOG_PATH")
    or "https://discord.com/api/webhooks/placeholder/webhook"
)

app_id = (
    os.getenv("APPLICATION_ID")
    or os.getenv("CLIENT_ID")
    or os.getenv("DISCORD_CLIENT_ID")
    or "1532027695914025222"
)

# Force-inject into runtime memory
os.environ["CHAT_LOG_CHANNEL_ID"] = chat_channel
os.environ["DISCORD_WEBHOOK_URL"] = webhook_url
os.environ["APPLICATION_ID"] = app_id

# 2. Write out the standard .env file
env_path = pathlib.Path("/app/.env")
env_content = f"""BOT_TOKEN={os.getenv('BOT_TOKEN', '')}
APPLICATION_ID={app_id}
CLIENT_ID={app_id}
DISCORD_CLIENT_ID={app_id}
BOT_PREFIX={os.getenv('BOT_PREFIX', '!')}
BOT_ACTIVITY={os.getenv('BOT_ACTIVITY', 'Palworld')}
BOT_LANGUAGE={os.getenv('BOT_LANGUAGE', 'en')}
CHAT_LOG_CHANNEL_ID={chat_channel}
DISCORD_CHANNEL_ID={chat_channel}
CHANNEL_ID={chat_channel}
CHAT_CHANNEL_ID={chat_channel}
DISCORD_WEBHOOK_URL={webhook_url}
DISCORD_WEBHOOK={webhook_url}
WEBHOOK_URL={webhook_url}
CHATLOG_PATH={webhook_url}
SERVER_IP={os.getenv('SERVER_IP', '')}
RCON_PORT={os.getenv('RCON_PORT', '25575')}
RCON_PASSWORD={os.getenv('RCON_PASSWORD', '')}
"""
env_path.write_text(env_content)

# 3. Check for and populate config.json / settings.json if used by the repo
config_candidates = [
    pathlib.Path("/app/config.json"),
    pathlib.Path("/app/src/config.json"),
    pathlib.Path("config.json"),
    pathlib.Path("src/config.json")
]

for cfg_path in config_candidates:
    try:
        if cfg_path.exists() or cfg_path.parent.exists():
            cfg_data = {}
            if cfg_path.exists():
                cfg_data = json.loads(cfg_path.read_text(encoding="utf-8"))
            
            # Inject keys into JSON config
            cfg_data["chat_log_channel_id"] = chat_channel
            cfg_data["chat_channel_id"] = chat_channel
            cfg_data["webhook_url"] = webhook_url
            cfg_data["discord_webhook_url"] = webhook_url
            cfg_data["token"] = os.getenv('BOT_TOKEN', '')
            
            cfg_path.write_text(json.dumps(cfg_data, indent=4), encoding="utf-8")
            print(f"Successfully updated configuration file at {cfg_path}")
            break
    except Exception as e:
        pass

print(".env and configuration sync completed successfully.")
print("--------------------------------------------------------")

# 4. Launch the application
main_script = "/app/src/main.py"
if not os.path.exists(main_script):
    main_script = "src/main.py"

subprocess.run([sys.executable, main_script])
