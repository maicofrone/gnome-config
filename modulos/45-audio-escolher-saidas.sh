TITULO="Áudio: escolher as saídas"
DESCRICAO="Lista as saídas de som do PC e pergunta quais devem aparecer no GNOME; esconde as outras."
PACOTES=(wireplumber libpulse python)
REGRA="50-saidas-de-audio.conf"

instalar() {
    local modo=()
    # Sem terminal ou com ./install.sh --tudo: não pergunta, usa a escolha salva
    if ((${TUDO:-0})) || [[ ! -t 0 ]]; then modo=(--automatico); fi
    python3 -I "$AQUI/apps/saidas-de-audio/escolher-saidas" "${modo[@]}" \
        --destino "$WP_DIR/$REGRA" \
        --padrao "$AQUI/config/wireplumber/wireplumber.conf.d/$REGRA"
}

desinstalar() {
    rm -f "$WP_DIR/$REGRA" "$WP_DIR/51-desativar-hdmi-nvidia.conf" "$WP_DIR/52-somente-analogico.conf"
    systemctl --user reset-failed wireplumber.service 2>/dev/null || true
    systemctl --user restart wireplumber.service || true
    verde "  ✓ Todas as saídas de áudio voltaram a aparecer"
}
