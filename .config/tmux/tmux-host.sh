#!/bin/sh
# ponytail: remote host from pane_title (denial@homebox:~) else local hostname
title="$1"
if printf "%s" "$title" | grep -q "@"; then
  printf "%s" "$title" | cut -d@ -f2 | cut -d: -f1 | cut -d' ' -f1 | cut -d~ -f1 | tr -d '[]' | tr -d "'\""
else
  hostname 2>/dev/null | cut -d. -f1
fi
