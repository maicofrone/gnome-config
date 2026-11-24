TITULO="Extensão: Ocultar indicadores"
DESCRICAO="Esconde da barra os ícones de Modo de energia e Luz noturna (continuam no menu rápido)."
PACOTES=()

instalar() {
    copiar_extensao ocultar-indicadores@local
    ativar_extensao ocultar-indicadores@local
    verde "  ✓ Ocultar indicadores instalado"
}

desinstalar() {
    remover_extensao ocultar-indicadores@local
    verde "  ✓ Ocultar indicadores removido"
}
