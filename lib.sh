# Funções compartilhadas pelo install.sh, uninstall.sh e pelos módulos.
# shellcheck shell=bash

AQUI="${AQUI:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
BIN_DIR="$HOME/.local/bin"
APPS_DIR="$HOME/.local/share/applications"
PW_DIR="$HOME/.config/pipewire/pipewire-pulse.conf.d"

verde()    { printf '\033[32m%s\033[0m\n' "$*"; }
amarelo()  { printf '\033[33m%s\033[0m\n' "$*"; }
vermelho() { printf '\033[31m%s\033[0m\n' "$*"; }
negrito()  { printf '\033[1m%s\033[0m\n' "$*"; }

# ---------- extensões do GNOME ----------
_lista_extensoes() {  # $1 = add|del, demais = uuids
    python3 -I - "$@" <<'PY'
import ast, subprocess, sys
modo, uuids = sys.argv[1], sys.argv[2:]
atual = subprocess.run(['gsettings', 'get', 'org.gnome.shell', 'enabled-extensions'],
                       capture_output=True, text=True).stdout.strip().removeprefix('@as ')
lista = ast.literal_eval(atual) if atual else []
if modo == 'add':
    lista += [u for u in uuids if u not in lista]
else:
    lista = [u for u in lista if u not in uuids]
subprocess.run(['gsettings', 'set', 'org.gnome.shell', 'enabled-extensions', str(lista)], check=True)
PY
}

ativar_extensao()    { _lista_extensoes add "$@"; gsettings set org.gnome.shell disable-user-extensions false; }
desativar_extensao() { _lista_extensoes del "$@"; }

# Copia extensions/<uuid> para a pasta do GNOME e compila os schemas
copiar_extensao() {
    local uuid="$1"
    mkdir -p "$EXT_DIR"
    rm -rf "${EXT_DIR:?}/$uuid"
    cp -r "$AQUI/extensions/$uuid" "$EXT_DIR/"
    if [[ -d "$EXT_DIR/$uuid/schemas" ]]; then
        glib-compile-schemas "$EXT_DIR/$uuid/schemas"
    fi
}

remover_extensao() {
    desativar_extensao "$1"
    rm -rf "${EXT_DIR:?}/$1"
}

# ---------- firewall ----------
# liberar_portas "Nome" "porta[:porta]" [proto...]   (padrão: tcp e udp)
liberar_portas() {
    local nome="$1" portas="$2"; shift 2
    local protos=("$@"); [[ $# -eq 0 ]] && protos=(tcp udp)
    if systemctl is-active --quiet ufw; then
        for p in "${protos[@]}"; do
            sudo ufw allow "$portas/$p" comment "$nome" >/dev/null
        done
        sudo ufw reload >/dev/null
    elif systemctl is-active --quiet firewalld; then
        for p in "${protos[@]}"; do
            sudo firewall-cmd --permanent --add-port="${portas/:/-}/$p" >/dev/null
        done
        sudo firewall-cmd --reload >/dev/null
    else
        amarelo "  Nenhum firewall ativo (ufw/firewalld): nada para liberar."
        return 0
    fi
    verde "  ✓ Portas $portas (${protos[*]}) liberadas para $nome"
}

fechar_portas() {
    local nome="$1" portas="$2"; shift 2
    local protos=("$@"); [[ $# -eq 0 ]] && protos=(tcp udp)
    if systemctl is-active --quiet ufw; then
        for p in "${protos[@]}"; do
            sudo ufw delete allow "$portas/$p" >/dev/null 2>&1 || true
        done
        sudo ufw reload >/dev/null
    elif systemctl is-active --quiet firewalld; then
        for p in "${protos[@]}"; do
            sudo firewall-cmd --permanent --remove-port="${portas/:/-}/$p" >/dev/null 2>&1 || true
        done
        sudo firewall-cmd --reload >/dev/null
    fi
    verde "  ✓ Portas $portas fechadas para $nome"
}

# Faixas de rede local (casa/escritório). Conexões de fora delas continuam bloqueadas.
REDES_LOCAIS=(192.168.0.0/16 10.0.0.0/8 172.16.0.0/12)

# Igual a liberar_portas, mas só aceita conexões vindas da rede local.
# liberar_portas_lan "Nome" "porta[:porta]" proto [proto...]
liberar_portas_lan() {
    local nome="$1" portas="$2"; shift 2
    local protos=("$@"); [[ $# -eq 0 ]] && protos=(tcp udp)
    if systemctl is-active --quiet ufw; then
        for rede in "${REDES_LOCAIS[@]}"; do
            for p in "${protos[@]}"; do
                sudo ufw allow from "$rede" to any port "$portas" proto "$p" comment "$nome" >/dev/null
            done
        done
        sudo ufw reload >/dev/null
    elif systemctl is-active --quiet firewalld; then
        for rede in "${REDES_LOCAIS[@]}"; do
            for p in "${protos[@]}"; do
                sudo firewall-cmd --permanent --add-rich-rule="rule family=ipv4 source address=$rede port port=${portas/:/-} protocol=$p accept" >/dev/null
            done
        done
        sudo firewall-cmd --reload >/dev/null
    else
        amarelo "  Nenhum firewall ativo (ufw/firewalld): nada para liberar."
        return 0
    fi
    verde "  ✓ Portas $portas (${protos[*]}) liberadas para $nome, só na rede local"
}

fechar_portas_lan() {
    local nome="$1" portas="$2"; shift 2
    local protos=("$@"); [[ $# -eq 0 ]] && protos=(tcp udp)
    if systemctl is-active --quiet ufw; then
        for rede in "${REDES_LOCAIS[@]}"; do
            for p in "${protos[@]}"; do
                sudo ufw delete allow from "$rede" to any port "$portas" proto "$p" >/dev/null 2>&1 || true
            done
        done
        sudo ufw reload >/dev/null
    elif systemctl is-active --quiet firewalld; then
        for rede in "${REDES_LOCAIS[@]}"; do
            for p in "${protos[@]}"; do
                sudo firewall-cmd --permanent --remove-rich-rule="rule family=ipv4 source address=$rede port port=${portas/:/-} protocol=$p accept" >/dev/null 2>&1 || true
            done
        done
        sudo firewall-cmd --reload >/dev/null
    fi
    verde "  ✓ Portas $portas fechadas para $nome"
}

# ---------- módulos ----------
# Cada arquivo em modulos/ define: TITULO, DESCRICAO, PACOTES=(...),
# e as funções instalar() e desinstalar().
listar_modulos() { find "$AQUI/modulos" -maxdepth 1 -name '*.sh' | sort; }

info_modulo() {  # imprime "TITULO|DESCRICAO|pacotes..."
    ( TITULO='' DESCRICAO='' PACOTES=()
      # shellcheck disable=SC1090
      source "$1"
      printf '%s|%s|%s\n' "$TITULO" "$DESCRICAO" "${PACOTES[*]}" )
}

rodar_modulo() {  # $1 = arquivo, $2 = instalar|desinstalar
    ( set -e
      # shellcheck disable=SC1090
      source "$1"
      "$2" )
}

# Pergunta sim/não. $1 = pergunta, $2 = padrão (s|n)
perguntar() {
    local resp padrao="${2:-s}" dica="[S/n]"
    [[ "$padrao" == n ]] && dica="[s/N]"
    read -r -p "$1 $dica " resp || resp=""
    resp="${resp:-$padrao}"
    [[ "${resp,,}" == s* || "${resp,,}" == y* ]]
}

# Mostra a lista e devolve em ESCOLHIDOS os módulos selecionados.
# $1 = verbo para o texto ("instalar" ou "remover")
escolher_modulos() {
    local verbo="$1" modulos=() f
    mapfile -t modulos < <(listar_modulos)
    ESCOLHIDOS=()

    echo
    negrito "Itens disponíveis:"
    
    for f in "${modulos[@]}"; do
        IFS='|' read -r titulo descricao _ < <(info_modulo "$f")
        printf '  • \033[1m%s\033[0m\n    \033[2m%s\033[0m\n' "$titulo" "$descricao"

    done
    echo
    echo "  1) ${verbo^} tudo"
    echo "  2) Escolher item por item"
    echo "  0) Cancelar"
    local opcao
    read -r -p "Opção [1]: " opcao || opcao=0
    case "${opcao:-1}" in
        1) ESCOLHIDOS=("${modulos[@]}") ;;
        2)
            echo
            for f in "${modulos[@]}"; do
                IFS='|' read -r titulo _ _ < <(info_modulo "$f")
                if perguntar "  ${verbo^} \"$titulo\"?"; then
                    ESCOLHIDOS+=("$f")
                fi
            done ;;
        *) echo "Cancelado."; exit 0 ;;
    esac
}
