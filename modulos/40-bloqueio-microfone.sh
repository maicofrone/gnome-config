TITULO="Microfone: bloquear apps de mudar o volume"
DESCRICAO="Regra do PipeWire + app \"Bloqueio do microfone\" para editar a lista."
PACOTES=(python-gobject gtk4 libadwaita libpulse)
REGRA="10-bloquear-volume-microfone.conf"

instalar() {
    mkdir -p "$BIN_DIR" "$APPS_DIR" "$PW_DIR"
    install -m 755 "$AQUI/apps/bloqueio-microfone/bloqueio-microfone" "$BIN_DIR/"
    sed "s|@BINDIR@|$BIN_DIR|" "$AQUI/apps/bloqueio-microfone/bloqueio-microfone.desktop" \
        > "$APPS_DIR/bloqueio-microfone.desktop"
    update-desktop-database "$APPS_DIR" 2>/dev/null || true
    verde "  ✓ App \"Bloqueio do microfone\" instalado"

    if cmp -s "$AQUI/config/pipewire/pipewire-pulse.conf.d/$REGRA" "$PW_DIR/$REGRA"; then
        verde "  ✓ Regra do microfone já está igual"
    else
        cp "$AQUI/config/pipewire/pipewire-pulse.conf.d/$REGRA" "$PW_DIR/"
        verde "  ✓ Regra do microfone copiada"
        if systemctl --user is-active --quiet pipewire-pulse.service; then
            amarelo "  Reiniciando o som. Apps como Claude e navegadores podem precisar"
            amarelo "  ser reabertos para achar o microfone."
            systemctl --user restart pipewire-pulse.service
        fi
    fi
}

desinstalar() {
    rm -f "$BIN_DIR/bloqueio-microfone" "$APPS_DIR/bloqueio-microfone.desktop"
    if [[ -f "$PW_DIR/$REGRA" ]]; then
        rm -f "$PW_DIR/$REGRA"
        systemctl --user restart pipewire-pulse.service || true
    fi
    verde "  ✓ Bloqueio do microfone removido"
}
