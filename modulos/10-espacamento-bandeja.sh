TITULO="Extensão: Espaçamento da bandeja"
DESCRICAO="Diminui a distância entre os ícones do lado direito da barra (6 px)."
PACOTES=(glib2)
ESPACAMENTO_PX=6

instalar() {
    copiar_extensao espacamento-bandeja@local
    ativar_extensao espacamento-bandeja@local
    GSETTINGS_SCHEMA_DIR="$EXT_DIR/espacamento-bandeja@local/schemas" \
        gsettings set org.gnome.shell.extensions.espacamento-bandeja padding "$ESPACAMENTO_PX"
    verde "  ✓ Espaçamento da bandeja instalado (${ESPACAMENTO_PX}px)"
}

desinstalar() {
    remover_extensao espacamento-bandeja@local
    verde "  ✓ Espaçamento da bandeja removido"
}
