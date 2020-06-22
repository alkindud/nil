#!/bin/sh
# https://www.shellhacks.com/ru/telegram-api-send-message-personal-notification-bot

BotID=
UserID=
curl -s -X POST https://api.telegram.org/bot$BotID/sendMessage -d chat_id=$UserID -d text="$@" >/dev/null
