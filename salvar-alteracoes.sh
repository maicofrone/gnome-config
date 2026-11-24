#!/usr/bin/env bash
# Copia de volta para esta pasta o que mudou no computador
# (por exemplo, apps que você bloqueou pelo app "Bloqueio do microfone").
# Rode antes de mandar para o GitHub.
set -euo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"

for e in ocultar-indicadores@local apps-no-menu@local firewall-toggle@local; do
    [[ -d "$EXT_DIR/$e" ]] || continue
    rm -rf "${AQUI:?}/extensions/$e"
    cp -r "$EXT_DIR/$e" "$AQUI/extensions/"
    rm -f "$AQUI/extensions/$e/schemas/gschemas.compiled"
done

cp "$HOME/.local/bin/bloqueio-microfone" "$AQUI/apps/bloqueio-microfone/" 2>/dev/null || true
cp "$HOME/.config/pipewire/pipewire-pulse.conf.d/10-bloquear-volume-microfone.conf" \
   "$AQUI/config/pipewire/pipewire-pulse.conf.d/" 2>/dev/null || true

echo "Pasta atualizada com o que está no computador."
command -v git >/dev/null && git -C "$AQUI" status --short
