TITULO="Extensão: Botão do firewall"
DESCRICAO="Botão no menu rápido para ligar/desligar o firewall (ufw), com senha. Mostra um alerta na barra enquanto estiver desligado."
PACOTES=(ufw polkit)

instalar() {
    copiar_extensao firewall-toggle@local
    ativar_extensao firewall-toggle@local
    verde "  ✓ Botão do firewall instalado"
}

desinstalar() {
    remover_extensao firewall-toggle@local
    verde "  ✓ Botão do firewall removido"
}
