TITULO="Extensão: Apps em segundo plano no menu"
DESCRICAO="Tira da barra os ícones de apps (Claude, Dropbox...) e os lista no menu rápido."
PACOTES=(gnome-shell-extension-appindicator)

instalar() {
    copiar_extensao apps-no-menu@local
    # Extensão de terceiros que faz os ícones de apps existirem
    ativar_extensao appindicatorsupport@rgcjonas.gmail.com apps-no-menu@local
    verde "  ✓ Apps em segundo plano no menu instalado"
}

desinstalar() {
    remover_extensao apps-no-menu@local
    verde "  ✓ Apps em segundo plano no menu removido (a AppIndicator continua ativa)"
}
