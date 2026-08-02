#!/usr/bin/env bash

case "$1" in
    --popup)
        theme=$(mktemp -d)
        mkdir -p "$theme/themes/TokyoNight/gtk-3.0"

        cat > "$theme/themes/TokyoNight/gtk-3.0/gtk.css" << 'THEME'
window, dialog {
    background-color: #1a1b26;
    color: #a9b1d6;
}
button {
    background-image: none;
    background-color: #24283b;
    color: #a9b1d6;
    border: 1px solid #32364a;
    border-radius: 4px;
    padding: 4px 8px;
}
button:hover {
    background-color: #32364a;
}
button:active {
    background-color: #7aa2f7;
    color: #1a1b26;
}
calendar {
    background-color: #1a1b26;
    color: #a9b1d6;
}
calendar:selected {
    background-color: #7aa2f7;
    color: #1a1b26;
}
calendar.header {
    background-color: #24283b;
    color: #7dcfff;
}
calendar.button {
    color: #7dcfff;
}
calendar:indeterminate {
    color: #565f89;
}
THEME

        cat > "$theme/themes/TokyoNight/index.theme" << 'THEME'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=TokyoNight
Encoding=UTF-8

[GTK 3.0]
MetaCategories=gtk-3.0
THEME

        XDG_DATA_DIRS="$theme:/usr/share" GTK_THEME=TokyoNight \
            yad --calendar \
            --title="Tokyo Calendar" \
            --button=Close:1 \
            --fixed \
            --on-top \
            --center \
            --borders=10 \
            --width=330 \
            --height=280 \
            2>/dev/null

        rm -rf "$theme"
        ;;
    *)
        date "+%a %b %d %H:%M"
        ;;
esac
