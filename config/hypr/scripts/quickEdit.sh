#!/bin/bash

# WOFI STYLES
CONFIG="$HOME/.config/hypr/wofi/config"
STYLE="$HOME/.config/hypr/wofi/style.css"
COLORS="$HOME/.config/hypr/wofi/colors"

hyprDir="$HOME/.config/hypr/configs"

# wofi window config (in %)
WIDTH=10
HEIGHT=40

## Wofi Command
wofi_command="wofi --show dmenu \
			--prompt choose...
			--conf $CONFIG --style $STYLE --color $COLORS \
			--width=$WIDTH% --height=$HEIGHT% \
			--cache-file=/dev/null \
			--hide-scroll --no-actions \
			--matching=fuzzy"


menu(){
  printf "1. view bind\n"
  printf "2. view rule\n"
  printf "3. view exec\n"
}

main() {
    choice=$(menu | ${wofi_command} | cut -d. -f1)
    case $choice in
        1)
            foot -e vim -R "$hyprDir/keybinds.conf"
            ;;
        2)
            foot -e vim -R "$hyprDir/window_rules.conf"
            ;;
        3)
            foot -e vim -R "$hyprDir/exec.conf"
            ;;
        *)
            ;;
    esac
}

main