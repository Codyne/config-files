#!/bin/bash
set -e

RICE_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.config/tokyo-rice-backup-$(date +%Y%m%d-%H%M%S)"

echo "=== Tokyo Night Rice Installer ==="
echo "Rice directory: $RICE_DIR"
echo ""

# ── Install packages ──────────────────────────────────────────────────
echo "==> Installing system packages..."
sudo apt-get install -y -qq \
    i3 polybar picom rofi feh terminator thunar yad dunst \
    fonts-firacode fonts-jetbrains-mono \
    curl unzip papirus-icon-theme sassc gtk2-engines-murrine \
    clangd rust-analyzer python3-pylsp 2>/dev/null || {
    echo "Warning: some packages failed to install (non-Debian system?)."
    echo "Install manually: i3 polybar picom rofi feh terminator thunar"
    echo "  fonts-firacode fonts-jetbrains-mono papirus-icon-theme"
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

# ── Install Nerd Font ─────────────────────────────────────────────────
if ! fc-list | grep -qi "JetBrainsMono.*Nerd" 2>/dev/null; then
    echo "==> Installing JetBrainsMono Nerd Font..."
    mkdir -p "$HOME/.fonts"
    curl -fSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip" \
        -o /tmp/jetbrains.zip
    unzip -o /tmp/jetbrains.zip -d "$HOME/.fonts" "*.ttf" 2>/dev/null
    fc-cache -fv "$HOME/.fonts" 2>/dev/null
    rm /tmp/jetbrains.zip
fi

# ── Backup existing configs ───────────────────────────────────────────
echo "==> Backing up existing configs to $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"
for f in \
    "$HOME/.config/i3/config" \
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

# ── Done ──────────────────────────────────────────────────────────────
echo ""
echo "=== Installation complete! ==="
echo ""
echo "What to do next:"
echo "  1. Reload i3:   \$mod+Shift+c"
echo "  2. Open Emacs: it will auto-install all packages on first start"
echo "     (or run M-x package-refresh-contents RET to force it)"
echo "     Key IDE bindings: C-c l d (def), C-c l r (refs), C-c l R (rename), C-c l h (hover)"
echo "  3. Restart Thunar for new icons"
echo ""
echo "Backup saved to: $BACKUP_DIR"
