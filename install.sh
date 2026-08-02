#!/bin/bash
set -e

RICE_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.config/tokyo-rice-backup-$(date +%Y%m%d-%H%M%S)"

# ── Helpers ──────────────────────────────────────────────────────────
ask_yn() {
    # ask_yn "Prompt" default(y|n); returns 0 for yes, 1 for no
    local prompt="$1" default="$2"
    local ans
    while :; do
        printf "%s (y/N): " "$prompt"
        if ! read -r ans; then ans="$default"; fi
        case "${ans:-$default}" in
            y|Y) return 0 ;;
            n|N) return 1 ;;
            *) echo "  Please answer y or n." >&2 ;;
        esac
    done
}

pick_from() {
    # pick_from "Prompt" default_index opts...; echoes the chosen option
    local prompt="$1" default="$2"; shift 2
    local opts=("$@")
    local i
    for i in "${!opts[@]}"; do
        echo "  [$((i+1))] ${opts[$i]}" >&2
    done
    local ans
    while :; do
        printf "%s [1-%d]: " "$prompt" "${#opts[@]}" >&2
        if ! read -r ans; then
            echo "${opts[$default]}"
            return 0
        fi
        if [[ -z "$ans" && -n "$default" ]]; then
            echo "${opts[$default]}"
            return 0
        fi
        if [[ "$ans" =~ ^[0-9]+$ ]] && (( ans >= 1 && ans <= ${#opts[@]} )); then
            echo "${opts[$((ans-1))]}"
            return 0
        fi
        echo "  Invalid selection, try again." >&2
    done
}

# ── Monitor detection ────────────────────────────────────────────────
# Populates global arrays:
#   MONITORS        connected monitor names in xrandr order
#   MON_MODE        current/preferred mode "WxH" per monitor
#   MON_RATE        current/preferred refresh rate per monitor
#   MON_ORIENT      current orientation per monitor
#   MON_IS_PRIMARY  "yes"/"no" per monitor
detect_monitors() {
    local out
    out="$(xrandr --query 2>/dev/null)" || { echo "  xrandr not available"; return 1; }
    MONITORS=()
    declare -g -A MON_MODE MON_RATE MON_ORIENT MON_IS_PRIMARY
    local cur="" line res rates tok rate cur_rate pref_rate rest
    while IFS= read -r line; do
        if [[ "$line" =~ ^([^ ]+)[[:space:]]+connected[[:space:]]+(.*) ]]; then
            cur="${BASH_REMATCH[1]}"
            rest="${BASH_REMATCH[2]}"
            MONITORS+=("$cur")
            MON_IS_PRIMARY["$cur"]="no"
            if [[ "$rest" == *primary* ]]; then MON_IS_PRIMARY["$cur"]="yes"; fi
            MON_MODE["$cur"]=""
            MON_RATE["$cur"]=""
            if [[ "$rest" =~ ^\(([a-z]+)[[:space:]] ]]; then
                MON_ORIENT["$cur"]="${BASH_REMATCH[1]}"
            else
                MON_ORIENT["$cur"]="normal"
            fi
        elif [[ -n "$cur" && -n "$line" && ! "$line" =~ connected ]]; then
            read -r res rates <<< "$line"
            if [[ "$res" =~ ^[0-9]+x[0-9]+$ ]]; then
                cur_rate=""; pref_rate=""
                for tok in $rates; do
                    rate="${tok//[^0-9.]/}"
                    if [[ -z "$cur_rate" && "$tok" == *"*"* ]]; then cur_rate="$rate"; fi
                    if [[ -z "$pref_rate" && "$tok" == *"+"* ]]; then pref_rate="$rate"; fi
                done
                if [[ -z "${MON_MODE[$cur]}" && -n "$cur_rate" ]]; then MON_MODE["$cur"]="$res"; fi
                if [[ -z "${MON_MODE[$cur]}" && -n "$pref_rate" ]]; then MON_MODE["$cur"]="$res"; fi
                if [[ -z "${MON_RATE[$cur]}" && -n "$cur_rate" ]]; then MON_RATE["$cur"]="$cur_rate"; fi
                if [[ -z "${MON_RATE[$cur]}" && -n "$pref_rate" ]]; then MON_RATE["$cur"]="$pref_rate"; fi
            fi
        elif [[ -z "$line" ]]; then
            cur=""
        fi
    done <<< "$out"
    local m
    for m in "${MONITORS[@]}"; do
        if [[ -z "${MON_MODE[$m]}" ]]; then MON_MODE["$m"]="1280x720"; fi
        if [[ -z "${MON_RATE[$m]}" ]]; then MON_RATE["$m"]="60"; fi
        if [[ -z "${MON_ORIENT[$m]}" ]]; then MON_ORIENT["$m"]="normal"; fi
    done
    return 0
}

eff_dims() {
    # eff_dims <mon> -> prints "W H" (effective on-screen dimensions after rotation)
    local mon="$1"
    local w="${MON_MODE[$mon]%%x*}"
    local h="${MON_MODE[$mon]##*x}"
    case "${MON_ORIENT[$mon]}" in
        left|right) echo "$h $w" ;;
        *) echo "$w $h" ;;
    esac
}

mon_pos() {
    # mon_pos <mon> <rel> -> prints "X Y" relative to the primary at the origin
    local mon="$1" rel="$2"
    local pw ph mw mh
    read -r pw ph <<< "$(eff_dims "$PRIMARY_MON")"
    read -r mw mh <<< "$(eff_dims "$mon")"
    case "$rel" in
        right)  echo "$pw 0" ;;
        left)   echo "$(( -mw )) 0" ;;
        above)  echo "0 $(( -mh ))" ;;
        below)  echo "0 $ph" ;;
    esac
}

nvidia_metamode_line() {
    local parts=() line p
    local mon W H R x y
    for mon in "${MONITORS[@]}"; do
        W="${MON_MODE[$mon]%%x*}"
        H="${MON_MODE[$mon]##*x}"
        R="${MON_RATE[$mon]%.*}"
        read -r x y <<< "${MON_POS[$mon]}"
        parts+=("$mon: ${W}x${H}_${R} +${x}+${y} {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}")
    done
    line='exec --no-startup-id nvidia-settings --assign CurrentMetaMode="'"${parts[0]}"
    for p in "${parts[@]:1}"; do
        line+=", $p"
    done
    line+='"'
    printf '%s\n' "$line"
}

generate_i3_monitor_conf() {
    local conf="$HOME/.config/i3/monitor.conf"
    local mon total w idx
    echo "==> Writing $conf"
    {
        echo "# Auto-generated by install.sh - machine-specific monitor layout."
        echo "# Re-run install.sh to regenerate. Safe to edit."
        echo ""
        echo "# Display configuration (mode, refresh rate, rotation, position, primary)"
        for mon in "${MONITORS[@]}"; do
            if [[ "$mon" == "$PRIMARY_MON" ]]; then
                echo "exec --no-startup-id xrandr --output $mon --mode ${MON_MODE[$mon]} --rate ${MON_RATE[$mon]} --rotate ${MON_ORIENT[$mon]} --pos ${MON_POS[$mon]} --primary"
            else
                echo "exec --no-startup-id xrandr --output $mon --mode ${MON_MODE[$mon]} --rate ${MON_RATE[$mon]} --rotate ${MON_ORIENT[$mon]} --pos ${MON_POS[$mon]}"
            fi
        done
        echo ""
        echo "# Workspace to monitor assignment (round-robin, starting on the primary)"
        local ordered=("$PRIMARY_MON")
        for mon in "${MONITORS[@]}"; do
            if [[ "$mon" != "$PRIMARY_MON" ]]; then ordered+=("$mon"); fi
        done
        total="${#ordered[@]}"
        for w in {1..10}; do
            idx=$(( (w - 1) % total ))
            echo "workspace $w output ${ordered[$idx]}"
        done
        if [[ "$NVIDIA_FIX" == "yes" ]]; then
            echo ""
            echo "# NVIDIA screen tearing fix (ForceCompositionPipeline)"
            echo "$(nvidia_metamode_line)"
        fi
    } > "$conf"
}

setup_monitors() {
    echo "==> Detecting monitors..."
    if ! detect_monitors || [ "${#MONITORS[@]}" -eq 0 ]; then
        echo "  No monitors detected (xrandr unavailable or not running under X)."
        echo "  Leaving default i3 config; no NVIDIA fix will be added."
        NVIDIA_FIX="no"
        mkdir -p "$HOME/.config/i3"
        {
            echo "# Auto-generated by install.sh"
            echo "# No monitors detected when this file was generated."
        } > "$HOME/.config/i3/monitor.conf"
        return
    fi
    echo "  Connected monitors: ${MONITORS[*]}"

    # ── Choose primary ──
    if [ "${#MONITORS[@]}" -eq 1 ]; then
        PRIMARY_MON="${MONITORS[0]}"
    else
        local default_primary=0 i
        for i in "${!MONITORS[@]}"; do
            if [[ "${MON_IS_PRIMARY[${MONITORS[$i]}]}" == "yes" ]]; then default_primary="$i"; fi
        done
        echo ""
        echo "  Which monitor should be the primary display?"
        PRIMARY_MON="$(pick_from "  Primary monitor" "$default_primary" "${MONITORS[@]}")"
    fi
    echo "  Primary: $PRIMARY_MON"

    # ── Choose orientation per monitor ──
    local mon def_orient
    for mon in "${MONITORS[@]}"; do
        def_orient=0
        case "${MON_ORIENT[$mon]}" in
            left) def_orient=1 ;;
            right) def_orient=2 ;;
            inverted) def_orient=3 ;;
            *) def_orient=0 ;;
        esac
        echo ""
        echo "  Orientation of $mon (current: ${MON_ORIENT[$mon]})?"
        MON_ORIENT["$mon"]="$(pick_from "  Orientation" "$def_orient" normal left right inverted)"
    done

    # ── Choose physical layout (position relative to the primary) ──
    declare -g -A MON_POS
    MON_POS["$PRIMARY_MON"]="0 0"
    local rel pos_x pos_y min_x=0 min_y=0
    for mon in "${MONITORS[@]}"; do
        if [[ "$mon" == "$PRIMARY_MON" ]]; then continue; fi
        echo ""
        echo "  Physical position of $mon relative to the primary ($PRIMARY_MON)?"
        rel="$(pick_from "  Position" "0" right left above below)"
        MON_POS["$mon"]="$(mon_pos "$mon" "$rel")"
    done
    # Normalize so the layout starts at the top-left corner (all coords >= 0)
    for mon in "${MONITORS[@]}"; do
        read -r pos_x pos_y <<< "${MON_POS[$mon]}"
        if (( pos_x < min_x )); then min_x="$pos_x"; fi
        if (( pos_y < min_y )); then min_y="$pos_y"; fi
    done
    for mon in "${MONITORS[@]}"; do
        read -r pos_x pos_y <<< "${MON_POS[$mon]}"
        MON_POS["$mon"]="$(( pos_x - min_x )) $(( pos_y - min_y ))"
    done

    # ── NVIDIA screen tearing fix ──
    echo ""
    NVIDIA_FIX="no"
    if ask_yn "  Add the NVIDIA screen tearing fix to the i3 config?" "n"; then
        if command -v nvidia-settings >/dev/null 2>&1; then
            NVIDIA_FIX="yes"
            echo "  NVIDIA tearing fix enabled."
        else
            echo "  nvidia-settings not found - skipping the NVIDIA tearing fix."
        fi
    fi

    generate_i3_monitor_conf
}

echo "=== Tokyo Night Rice Installer ==="
echo "Rice directory: $RICE_DIR"
echo ""

# ── Install packages ──────────────────────────────────────────────────
echo "==> Installing system packages..."
sudo apt-get install -y -qq \
    i3 polybar picom rofi feh terminator thunar yad dunst \
    fonts-liberation \
    curl unzip papirus-icon-theme sassc gtk2-engines-murrine \
    clangd rust-analyzer python3-pylsp 2>/dev/null || {
    echo "Warning: some packages failed to install (non-Debian system?)."
    echo "Install manually: i3 polybar picom rofi feh terminator thunar"
    echo "  fonts-liberation papirus-icon-theme"
}

# ── Install Kotlin Language Server ─────────────────────────────────────
echo "==> Installing Kotlin Language Server..."
mkdir -p "$HOME/.local/bin"
KLS_BIN="$HOME/.local/bin/kotlin-language-server"
if [ ! -f "$KLS_BIN" ]; then
    curl -fSL "https://github.com/fwcd/kotlin-language-server/releases/download/1.3.12/server.zip" \
        -o /tmp/kls.zip
    unzip -o /tmp/kls.zip -d "$HOME/.local/share/kotlin-language-server" 2>/dev/null
    ln -sf "$HOME/.local/share/kotlin-language-server/server/bin/kotlin-language-server" "$KLS_BIN"
    chmod +x "$KLS_BIN"
    rm /tmp/kls.zip
fi

# Add ~/.local/bin to PATH if not already
case ":$PATH:" in
    *:"$HOME/.local/bin":*) ;;
    *) echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc" ;;
esac

# ── Monitor setup ────────────────────────────────────────────────────
# Detects connected monitors and asks the user about primary display,
# per-monitor orientation, and the NVIDIA screen tearing fix. Writes the
# machine-specific layout to ~/.config/i3/monitor.conf (pulled in via the
# i3 config's `include`).
echo ""
echo "==> Monitor setup"
setup_monitors

# ── Backup existing configs ───────────────────────────────────────────
echo "==> Backing up existing configs to $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"
for f in \
    "$HOME/.config/i3/config" \
    "$HOME/.config/i3/monitor.conf" \
    "$HOME/.config/i3/lock.sh" \
    "$HOME/.config/polybar/config.ini" \
    "$HOME/.config/dunst/dunstrc" \
    "$HOME/.config/ncmpcpp/config" \
    "$HOME/.config/picom/picom.conf" \
    "$HOME/.config/rofi/tokyo-night.rasi" \
    "$HOME/.config/rofi/config.rasi" \
    "$HOME/.config/terminator/config" \
    "$HOME/.config/gtk-3.0/settings.ini" \
    "$HOME/.config/gtk-3.0/gtk.css" \
    "$HOME/.emacs.d/init.el" \
    "$HOME/.Xresources" \
    "$HOME/.bashrc" \
    "$HOME/.inputrc"; do
    [ -f "$f" ] && cp --parents "$f" "$BACKUP_DIR" 2>/dev/null || true
done

# ── Symlink configs ───────────────────────────────────────────────────
echo "==> Installing configs..."

mkdir -p "$HOME/.config/i3"
ln -sf "$RICE_DIR/config/i3/config" "$HOME/.config/i3/config"
ln -sf "$RICE_DIR/config/i3/lock.sh" "$HOME/.config/i3/lock.sh"

mkdir -p "$HOME/.config/dunst"
ln -sf "$RICE_DIR/config/dunst/dunstrc" "$HOME/.config/dunst/dunstrc"

mkdir -p "$HOME/.config/ncmpcpp"
ln -sf "$RICE_DIR/config/ncmpcpp/config" "$HOME/.config/ncmpcpp/config"

mkdir -p "$HOME/.config/polybar"
ln -sf "$RICE_DIR/config/polybar/config.ini" "$HOME/.config/polybar/config.ini"
ln -sf "$RICE_DIR/config/polybar/launch.sh" "$HOME/.config/polybar/launch.sh"
mkdir -p "$HOME/.config/polybar/scripts"
ln -sf "$RICE_DIR/config/polybar/scripts/calendar.sh" "$HOME/.config/polybar/scripts/calendar.sh"

mkdir -p "$HOME/.config/picom"
ln -sf "$RICE_DIR/config/picom/picom.conf" "$HOME/.config/picom/picom.conf"

mkdir -p "$HOME/.config/rofi"
ln -sf "$RICE_DIR/config/rofi/tokyo-night.rasi" "$HOME/.config/rofi/tokyo-night.rasi"
ln -sf "$RICE_DIR/config/rofi/config.rasi" "$HOME/.config/rofi/config.rasi"

mkdir -p "$HOME/.config/terminator"
ln -sf "$RICE_DIR/config/terminator/config" "$HOME/.config/terminator/config"

mkdir -p "$HOME/.config/zathura"
ln -sf "$RICE_DIR/config/zathura/zathurarc" "$HOME/.config/zathura/zathurarc"

mkdir -p "$HOME/.config/gtk-3.0"
ln -sf "$RICE_DIR/config/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
ln -sf "$RICE_DIR/config/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"

mkdir -p "$HOME/.emacs.d"
ln -sf "$RICE_DIR/emacs.d/init.el" "$HOME/.emacs.d/init.el"

ln -sf "$RICE_DIR/Xresources" "$HOME/.Xresources"

ln -sf "$RICE_DIR/bashrc" "$HOME/.bashrc"

ln -sf "$RICE_DIR/inputrc" "$HOME/.inputrc"

mkdir -p "$HOME/Pictures/wallpapers"
ln -sf "$RICE_DIR/wallpapers/tokyo-night.png" "$HOME/Pictures/wallpapers/tokyo-night.png"

# ── Install Tokyonight GTK Theme ──────────────────────────────────────
echo "==> Installing Tokyonight GTK theme..."
if [ ! -d "$HOME/.themes/Tokyonight-Dark" ]; then
    bash "$RICE_DIR/themes/Tokyonight-GTK-Theme/themes/install.sh" -c dark 2>/dev/null
    # Patch invalid GTK CSS properties
    sed -i '/border-spacing/d' "$HOME/.themes/Tokyonight-Dark/gtk-3.0/gtk.css" 2>/dev/null
    sed -i '/border-spacing/d' "$HOME/.themes/Tokyonight-Dark/gtk-3.0/gtk-dark.css" 2>/dev/null
fi

# ── Optional Language Servers ─────────────────────────────────────────
echo "==> Installing optional language servers..."
pip3 install --user python-lsp-black python-lsp-isort 2>/dev/null || true
# For JS/TS/Bash/HTML/CSS language servers, install Node.js then:
#   npm install -g typescript-language-server bash-language-server vscode-langservers-extracted
# For PHP: composer global require phpactor/phpactor
# For Dart/Flutter: install from https://dart.dev/get-dart

# ── Apply Xresources ──────────────────────────────────────────────────
echo "==> Applying Xresources..."
xrdb -merge "$HOME/.Xresources" 2>/dev/null || true

# ── Restart i3  ───────────────────────────────────────────────────────
i3-msg restart

# ── Done ──────────────────────────────────────────────────────────────
echo ""
echo "=== Installation complete! ==="
echo ""
echo "What to do next?"
echo "  Try Emacs: it will auto-install all packages on first start"
echo "  (or run M-x package-refresh-contents RET to force it)"
echo "  Key IDE bindings: C-c l d (def), C-c l r (refs), C-c l R (rename), C-c l h (hover)"
echo ""
echo "Backup saved to: $BACKUP_DIR"
