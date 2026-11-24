#!/usr/bin/env bash
# Remove tudo o que o install.sh instalou (não remove pacotes do sistema).
set -euo pipefail

EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
EXTENSOES=(espacamento-bandeja@local ocultar-indicadores@local apps-no-menu@local)

python3 -I - "${EXTENSOES[@]}" <<'PY'
import ast, subprocess, sys
atual = subprocess.run(['gsettings', 'get', 'org.gnome.shell', 'enabled-extensions'],
                       capture_output=True, text=True).stdout.strip().removeprefix('@as ')
lista = [e for e in (ast.literal_eval(atual) if atual else []) if e not in sys.argv[1:]]
subprocess.run(['gsettings', 'set', 'org.gnome.shell', 'enabled-extensions', str(lista)], check=True)
PY

for e in "${EXTENSOES[@]}"; do rm -rf "${EXT_DIR:?}/$e"; done
rm -f "$HOME/.local/bin/bloqueio-microfone" "$HOME/.local/share/applications/bloqueio-microfone.desktop"

REGRA="$HOME/.config/pipewire/pipewire-pulse.conf.d/10-bloquear-volume-microfone.conf"
if [[ -f "$REGRA" ]]; then
    rm -f "$REGRA"
    systemctl --user restart pipewire-pulse.service || true
fi

echo "Removido. Saia da sessão e entre de novo para o GNOME descarregar as extensões."
