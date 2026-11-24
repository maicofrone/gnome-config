TITULO="Extensão: Botão do firewall"
DESCRICAO="Botão no menu rápido para ligar/desligar o firewall (ufw). Desligar pede senha, ligar não. Escudo cortado na barra enquanto estiver desligado, e o firewall volta ligado ao reiniciar. Pede senha (sudo)."
PACOTES=(ufw polkit)
EXT="extensions/firewall-toggle@local"

instalar() {
    copiar_extensao firewall-toggle@local
    ativar_extensao firewall-toggle@local
    verde "  ✓ Botão do firewall instalado"

    # Mesmo conteúdo que a extensão instalaria sozinha na primeira vez que for usada
    sudo install -D -m 644 "$AQUI/$EXT/religar-no-boot.conf" /etc/systemd/system/ufw.service.d/religar-no-boot.conf
    sudo install -D -m 644 "$AQUI/$EXT/49-firewall-toggle.rules" /etc/polkit-1/rules.d/49-firewall-toggle.rules
    local versao
    versao=$(printf '%s\n%s' "$(cat "$AQUI/$EXT/religar-no-boot.conf"; printf x)" "$(cat "$AQUI/$EXT/49-firewall-toggle.rules"; printf x)" \
        | sed 's/x$//' | sha256sum | cut -d' ' -f1)
    sudo mkdir -p /usr/local/share/firewall-toggle
    printf %s "$versao" | sudo tee /usr/local/share/firewall-toggle/versao >/dev/null
    sudo systemctl daemon-reload
    verde "  ✓ Firewall volta ligado ao reiniciar, e ligar não pede senha"
}

desinstalar() {
    remover_extensao firewall-toggle@local
    sudo rm -f /etc/systemd/system/ufw.service.d/religar-no-boot.conf \
               /etc/polkit-1/rules.d/49-firewall-toggle.rules
    sudo rm -rf /usr/local/share/firewall-toggle
    sudo rmdir /etc/systemd/system/ufw.service.d 2>/dev/null || true
    sudo systemctl daemon-reload
    verde "  ✓ Botão do firewall removido"
}
