#!/usr/bin/env bash
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

if ! command -v xrandr >/dev/null 2>&1; then
    polybar main &
    exit 0
fi

primary="$(xrandr --query | awk '/ connected primary/ {print $1; exit}')"

for m in $(xrandr --query | awk '/ connected/ {print $1}'); do
    if [[ -z "$primary" || "$m" == "$primary" ]]; then
        MONITOR="$m" polybar main &
    else
        MONITOR="$m" polybar second &
    fi
done
