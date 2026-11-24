#!/usr/bin/env bash
# Instala minhas configurações do GNOME:
#   - extensões: espacamento-bandeja, ocultar-indicadores, apps-no-menu
#   - app "Bloqueio do microfone" + regra do PipeWire
#
# Uso:  ./install.sh            (instala tudo)
#       ./install.sh --sem-pacotes   (não tenta instalar pacotes do sistema)
set -euo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"
PW_DIR="$HOME/.config/pipewire/pipewire-pulse.conf.d"
REGRA="10-bloquear-volume-microfone.conf"

EXTENSOES=(espacamento-bandeja@local ocultar-indicadores@local apps-no-menu@local)
# Extensão de terceiros necessária para os ícones de apps (Claude, Dropbox...)
APPINDICATOR="appindicatorsupport@rgcjonas.gmail.com"
ESPACAMENTO_PX=6

verde() { printf '\033[32m%s\033[0m\n' "$*"; }
amarelo() { printf '\033[33m%s\033[0m\n' "$*"; }

# ---------- 1. Pacotes do sistema ----------
PACOTES=(gnome-shell-extension-appindicator python-gobject libadwaita gtk4 glib2 libpulse)
if [[ "${1:-}" != "--sem-pacotes" ]] && command -v pacman >/dev/null; then
    faltando=()
    for p in "${PACOTES[@]}"; do
        pacman -Qi "$p" >/dev/null 2>&1 || faltando+=("$p")
    done
    if ((${#faltando[@]})); then
        amarelo "Pacotes faltando: ${faltando[*]}"
        sudo pacman -S --needed "${faltando[@]}"
    else
        verde "✓ Pacotes do sistema já instalados"
    fi
elif ! command -v pacman >/dev/null; then
    amarelo "! Sistema sem pacman: instale manualmente o equivalente a: ${PACOTES[*]}"
fi

# ---------- 2. Extensões ----------
mkdir -p "$EXT_DIR"
for e in "${EXTENSOES[@]}"; do
    rm -rf "${EXT_DIR:?}/$e"
    cp -r "$AQUI/extensions/$e" "$EXT_DIR/"
    if [[ -d "$EXT_DIR/$e/schemas" ]]; then
        glib-compile-schemas "$EXT_DIR/$e/schemas"
    fi
done
verde "✓ Extensões copiadas"

# Ativa as extensões (mantém as que já estavam ativas)
python3 -I - "$APPINDICATOR" "${EXTENSOES[@]}" <<'PY'
import ast, subprocess, sys
atual = subprocess.run(['gsettings', 'get', 'org.gnome.shell', 'enabled-extensions'],
                       capture_output=True, text=True).stdout.strip()
atual = atual.removeprefix('@as ')
lista = ast.literal_eval(atual) if atual else []
for e in sys.argv[1:]:
    if e not in lista:
        lista.append(e)
subprocess.run(['gsettings', 'set', 'org.gnome.shell', 'enabled-extensions', str(lista)], check=True)
PY
gsettings set org.gnome.shell disable-user-extensions false
verde "✓ Extensões ativadas"

# Espaçamento da bandeja
GSETTINGS_SCHEMA_DIR="$EXT_DIR/espacamento-bandeja@local/schemas" \
    gsettings set org.gnome.shell.extensions.espacamento-bandeja padding "$ESPACAMENTO_PX" \
    && verde "✓ Espaçamento da bandeja: ${ESPACAMENTO_PX}px"

# ---------- 3. App "Bloqueio do microfone" ----------
mkdir -p "$BIN_DIR" "$APPS_DIR"
install -m 755 "$AQUI/apps/bloqueio-microfone/bloqueio-microfone" "$BIN_DIR/"
sed "s|@BINDIR@|$BIN_DIR|" "$AQUI/apps/bloqueio-microfone/bloqueio-microfone.desktop" \
    > "$APPS_DIR/bloqueio-microfone.desktop"
update-desktop-database "$APPS_DIR" 2>/dev/null || true
verde "✓ App \"Bloqueio do microfone\" instalado"

# ---------- 4. Regra do PipeWire ----------
mkdir -p "$PW_DIR"
if cmp -s "$AQUI/config/pipewire/pipewire-pulse.conf.d/$REGRA" "$PW_DIR/$REGRA"; then
    verde "✓ Regra do microfone já está igual"
else
    cp "$AQUI/config/pipewire/pipewire-pulse.conf.d/$REGRA" "$PW_DIR/"
    verde "✓ Regra do microfone copiada"
    if systemctl --user is-active --quiet pipewire-pulse.service; then
        amarelo "  Reiniciando o som para aplicar (apps como Claude e navegadores"
        amarelo "  podem precisar ser reabertos para achar o microfone)."
        systemctl --user restart pipewire-pulse.service
    fi
fi

echo
verde "Tudo instalado!"
amarelo "Saia da sessão e entre de novo para o GNOME carregar as extensões."
