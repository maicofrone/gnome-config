TITULO="Firewall: liberar KDE Connect"
DESCRICAO="Instala o KDE Connect e abre as portas 1714-1764 (TCP/UDP) para o celular conectar. Pede senha (sudo)."
PACOTES=(kdeconnect)
PORTAS="1714:1764"

instalar() {
    liberar_portas "KDE Connect" "$PORTAS"
}

desinstalar() {
    fechar_portas "KDE Connect" "$PORTAS"
    # Regra antiga criada pelo perfil do ufw, se existir
    if systemctl is-active --quiet ufw; then
        sudo ufw delete allow "KDE Connect" >/dev/null 2>&1 || true
    fi
}
