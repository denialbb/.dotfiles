#!/bin/bash
# Rebuild + install the denial Plymouth boot theme from scratch.
# Inputs: omarchy base theme (package) + tracked source art in this dir.
# Usage (as USER, not sudo): ./build-denial-theme.sh [source-png]
# Then: sudo limine-mkinitcpio   (UKI rebuild; plain mkinitcpio -P has no presets here)
set -e

if ((EUID == 0)); then
  echo "Run as user, not sudo (sudo is used internally for install)." >&2
  exit 1
fi

BRAND_DIR="$HOME/.config/omarchy/branding"
SRC_ART="${1:-$BRAND_DIR/denial-logo-new-1.png}"
BASE=/usr/share/plymouth/themes/omarchy
ACC_R=60 ACC_G=191 ACC_B=92  # Matrix #3CBF5C

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
cp -r "$BASE" "$WORK/denial"
rm -rf "$WORK/denial/logos" "$WORK/denial/preview-unlock.png"
cd "$WORK/denial"
mv omarchy.plymouth denial.plymouth
mv omarchy.script denial.script

sed -i -e 's/^Name=.*/Name=Denial/' \
  -e 's/^Description=.*/Description=Denial matrix splash./' \
  -e 's|/omarchy$|/denial|' \
  -e 's|ScriptFile=.*|ScriptFile=/usr/share/plymouth/themes/denial/denial.script|' \
  -e 's/ConsoleLogBackgroundColor=.*/ConsoleLogBackgroundColor=0x080C09/' denial.plymouth
# Tokyo Night #1a1b26 -> Matrix #080C09
sed -i 's/Window.SetBackground\(Top\|Bottom\)Color(0.101, 0.105, 0.149)/Window.SetBackground\1Color(0.031, 0.047, 0.035)/' denial.script

python3 - "$SRC_ART" <<'PYEOF'
import sys
from PIL import Image
ACC = (60, 191, 92)
# green-dominant pixels -> phosphor green, luminance kept
for n in ['lock', 'entry', 'bullet']:
    im = Image.open(n + '.png').convert('RGBA')
    px = im.load()
    for y in range(im.size[1]):
        for x in range(im.size[0]):
            r, g, b, a = px[x, y]
            if a > 8 and g > 60 and g >= r and g >= b:
                k = (0.299 * r + 0.587 * g + 0.114 * b) / 255
                px[x, y] = (int(ACC[0] * k), int(ACC[1] * k), int(ACC[2] * k), a)
    im.save(n + '.png')
# 1-bit progress assets: palette index 0 is the fg color
for n, fg in [('progress_box', (0x12, 0x1A, 0x13)), ('progress_bar', ACC)]:
    im = Image.open(n + '.png')
    raw = bytearray(im.palette.palette)
    raw[0:3] = bytes(fg)
    im.putpalette(raw)
    im.save(n + '.png')
# source art -> 800x188 slot, lifted to visible green
src = Image.open(sys.argv[1]).convert('RGBA')
w, h = src.size
s = min(800 / w, 188 / h, 1.0)
src = src.resize((int(w * s), int(h * s)), Image.LANCZOS)
px = src.load()
for y in range(src.size[1]):
    for x in range(src.size[0]):
        r, g, b, a = px[x, y]
        if a > 8:
            k = min(1.0, (0.299 * r + 0.587 * g + 0.114 * b) / 255 * 1.6 + 0.30)
            px[x, y] = (int(ACC[0] * k), int(ACC[1] * k), int(ACC[2] * k), a)
canvas = Image.new('RGBA', (800, 188), (0, 0, 0, 0))
canvas.paste(src, ((800 - src.size[0]) // 2, (188 - src.size[1]) // 2), src)
canvas.save('logo.png')
print('built logo.png from', sys.argv[1])
PYEOF

sudo rm -rf /usr/share/plymouth/themes/denial
sudo cp -r "$WORK/denial" /usr/share/plymouth/themes/denial
sudo chmod 755 /usr/share/plymouth/themes/denial
sudo chmod 644 /usr/share/plymouth/themes/denial/*
sudo plymouth-set-default-theme denial
echo "Installed. Rebuild UKIs: sudo limine-mkinitcpio"
