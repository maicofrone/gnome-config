TITULO="Extensão: Botão do firewall"
DESCRICAO="Botão no menu rápido para ligar/desligar o firewall (ufw), com senha. Alerta na barra enquanto estiver desligado, e o firewall volta ligado ao reiniciar. Pede senha (sudo)."
PACOTES=(ufw polkit)
DROPIN_DIR="/etc/systemd/system/ufw.service.d"
DROPIN="religar-no-boot.conf"

instalar() {
    copiar_extensao firewall-toggle@local
    ativar_extensao firewall-toggle@local
    verde "  ✓ Botão do firewall instalado"

    # Faz o ufw sempre voltar ligado ao reiniciar
    sudo install -D -m 644 "$AQUI/config/systemd/ufw.service.d/$DROPIN" "$DROPIN_DIR/$DROPIN"
    sudo systemctl daemon-reload
    verde "  ✓ Firewall volta ligado sempre que o computador reiniciar"
}

desinstalar() {
    remover_extensao firewall-toggle@local
    if [[ -f "$DROPIN_DIR/$DROPIN" ]]; then
        sudo rm -f "$DROPIN_DIR/$DROPIN"
        sudo rmdir "$DROPIN_DIR" 2>/dev/null || true
        sudo systemctl daemon-reload
    fi
    verde "  ✓ Botão do firewall removido"
}
