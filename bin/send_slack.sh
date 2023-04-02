#!/bin/bash


message="${@:1}"

echo "send message $message"

curl -X POST --data-urlencode "payload={\"channel\": \"#disagg-eval\", \"username\": \"ubuntu\", \"text\": \"$message.\", \"icon_emoji\": \":fries:\"}" https://hooks.slack.com/services/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
