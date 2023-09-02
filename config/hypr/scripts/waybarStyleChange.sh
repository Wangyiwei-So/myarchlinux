#!/bin/bash

# Check which waybar theme is set
THEMEIS=$(realpath ~/.config/hypr/waybar/style.css | sed 's/.*-\(.*\)\.css/\1/')

# Change theme
if [ "$THEMEIS" == "default" ]; then
    SWITCHTO="-light"
elif [ "$THEMEIS" == "light" ]; then
    SWITCHTO="-dark"
else
    SWITCHTO="-default"
fi

# Set the waybar theme
THEMEFILE="$HOME/.config/hypr/waybar/style/style${SWITCHTO}.css"
if [ -f "$THEMEFILE" ]; then
    ln -sf "$THEMEFILE" "$HOME/.config/hypr/waybar/style.css"

else
    echo "Error: $THEMEFILE not found"
    exit 1
fi

# Restart waybar
killall waybar
exec ~/.config/hypr/scripts/statusbar.sh



