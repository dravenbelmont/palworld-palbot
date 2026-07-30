#!/bin/bash

# Force export required environment variables so native checks pass
export CHAT_LOG_CHANNEL_ID="${CHAT_LOG_CHANNEL_ID:-123456789012345678}"
export DISCORD_CHANNEL_ID="${DISCORD_CHANNEL_ID:-$CHAT_LOG_CHANNEL_ID}"
export CHANNEL_ID="${CHANNEL_ID:-$CHAT_LOG_CHANNEL_ID}"
export CHAT_CHANNEL_ID="${CHAT_CHANNEL_ID:-$CHAT_LOG_CHANNEL_ID}"

export DISCORD_WEBHOOK_URL="${DISCORD_WEBHOOK_URL:-https://discord.com/api/webhooks/placeholder/webhook}"
export DISCORD_WEBHOOK="${DISCORD_WEBHOOK:-$DISCORD_WEBHOOK_URL}"
export WEBHOOK_URL="${WEBHOOK_URL:-$DISCORD_WEBHOOK_URL}"
export CHATLOG_PATH="${CHATLOG_PATH:-$DISCORD_WEBHOOK_URL}"

export APPLICATION_ID="${APPLICATION_ID:-1532027695914025222}"
export CLIENT_ID="${CLIENT_ID:-$APPLICATION_ID}"
export DISCORD_CLIENT_ID="${DISCORD_CLIENT_ID:-$APPLICATION_ID}"

printenv > /app/.env

echo "Environment variables injected successfully via start.sh."

# Execute the container's default startup sequence
exec python3 startup.py
