#!/usr/bin/env bash
# Remove as configurações instaladas pelo install.sh, deixando escolher o quê.
# Não remove pacotes do sistema.
#
# Uso:  ./uninstall.sh          menu: remover tudo ou escolher item por item
#       ./uninstall.sh --tudo   remove tudo sem perguntar
set -uo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$AQUI/lib.sh"

negrito "═══ Remoção das configurações do GNOME ═══"

if [[ "${1:-}" == "--tudo" ]]; then
    mapfile -t ESCOLHIDOS < <(listar_modulos)
else
    escolher_modulos remover
fi

for f in "${ESCOLHIDOS[@]}"; do
    IFS='|' read -r titulo _ _ < <(info_modulo "$f")
    echo
    negrito "▶ $titulo"
    rodar_modulo "$f" desinstalar || vermelho "  ✗ Falhou"
done

echo
amarelo "Pronto. Se removeu extensões, saia da sessão e entre de novo."
