#!/usr/bin/env bash
# Instala minhas configurações do GNOME, deixando escolher o que instalar.
#
# Uso:  ./install.sh                 menu: instalar tudo ou escolher item por item
#       ./install.sh --tudo          instala tudo sem perguntar
#       ./install.sh --sem-pacotes   não instala pacotes do sistema (pacman)
#
# Cada item é um arquivo em modulos/. Para adicionar um item novo, copie um
# módulo existente e mude o TITULO, DESCRICAO, PACOTES, instalar() e desinstalar().
set -uo pipefail

AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$AQUI/lib.sh"

TUDO=0; PACOTES_SIM=1
for arg in "$@"; do
    case "$arg" in
        --tudo) TUDO=1 ;;
        --sem-pacotes) PACOTES_SIM=0 ;;
        -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
        *) vermelho "Opção desconhecida: $arg"; exit 1 ;;
    esac
done

negrito "═══ Instalação das configurações do GNOME ═══"

if ((TUDO)); then
    mapfile -t ESCOLHIDOS < <(listar_modulos)
else
    escolher_modulos instalar
fi

if ((${#ESCOLHIDOS[@]} == 0)); then
    echo "Nada escolhido."
    exit 0
fi

# ---------- pacotes do sistema ----------
if ((PACOTES_SIM)); then
    precisa=()
    for f in "${ESCOLHIDOS[@]}"; do
        IFS='|' read -r _ _ pacotes < <(info_modulo "$f")
        for p in $pacotes; do precisa+=("$p"); done
    done
    if command -v pacman >/dev/null; then
        faltando=()
        for p in $(printf '%s\n' "${precisa[@]}" | sort -u); do
            pacman -Qi "$p" >/dev/null 2>&1 || faltando+=("$p")
        done
        if ((${#faltando[@]})); then
            echo
            amarelo "Pacotes que faltam: ${faltando[*]}"
            sudo pacman -S --needed "${faltando[@]}" || vermelho "Falha ao instalar pacotes; continuando."
        fi
    elif ((${#precisa[@]})); then
        amarelo "Sem pacman: instale manualmente o equivalente a: ${precisa[*]}"
    fi
fi

# ---------- instala cada item ----------
ok=(); falhou=()
for f in "${ESCOLHIDOS[@]}"; do
    IFS='|' read -r titulo _ _ < <(info_modulo "$f")
    echo
    negrito "▶ $titulo"
    if rodar_modulo "$f" instalar; then
        ok+=("$titulo")
    else
        vermelho "  ✗ Falhou"
        falhou+=("$titulo")
    fi
done

echo
negrito "═══ Resumo ═══"
for t in "${ok[@]}"; do verde "  ✓ $t"; done
for t in "${falhou[@]}"; do vermelho "  ✗ $t"; done
if printf '%s\n' "${ok[@]}" | grep -q "^Extensão"; then
    echo
    amarelo "Saia da sessão e entre de novo para o GNOME carregar as extensões."
fi
((${#falhou[@]} == 0))
