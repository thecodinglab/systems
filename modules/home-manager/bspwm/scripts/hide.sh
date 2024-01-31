#!/usr/bin/env sh

xdotool search --class $1 | xargs -I{} bspc node {} --flag hidden -f
