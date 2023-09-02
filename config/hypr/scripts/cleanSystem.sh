#!/bin/sh
echo "input sudo pass to clean"
sudo pacman -Rs $(pacman -Qdtq)
sudo pacman -Sc

