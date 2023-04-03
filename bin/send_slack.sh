#!/bin/bash


message="$@"

echo "send message $message"

slack() {
  local secret
  if [[ -f ~/wonook_scripts/nemoqa/slack.secret ]]; then
    secret=$(cat ~/wonook_scripts/nemoqa/slack.secret)
    curl -X POST --data-urlencode "payload={\"channel\": \"#disagg-eval\", \"username\":\"blazebot\", \"icon_emoji\":\":ghost:\", \"text\": \"$1\"}" "$secret"
  fi
}

slack "$message"
