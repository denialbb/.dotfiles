#!/bin/bash

LANGS=(go java php)
OPTIONS="--border=rounded --height=100 --layout=reverse --info=inline"
BASE_URL="https://cheat.sh"

lang=$(printf "%s\n" "${LANGS[@]}" | fzf --prompt="Select a programming language: " $OPTIONS)
read -rp "Your query: " query

curl -s "$BASE_URL/$lang/$query" | bat
