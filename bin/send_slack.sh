#!/bin/bash


message="${@:1}"

echo "send message $message"


  local secret
  if [[ -f ~/wonook_scripts/nemoqa/slack.secret ]]; then
    secret=$(cat ~/wonook_scripts/nemoqa/slack.secret)
    curl -X POST --data-urlencode "payload={\"text\": \"$1\"}" "$secret"
curl -X POST --data-urlencode "payload={\"channel\": \"#disagg-eval\", \"username\": \"ubuntu\", \"text\": \"$message.\", \"icon_emoji\": \":fries:\"}" "$secret"
  fi


