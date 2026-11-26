TITULO="Extensão: Mouse sem travar ao trocar de música"
DESCRICAO="Agrupa as rajadas de avisos de mídia do navegador (YouTube Music no Vivaldi/Chrome) para o mouse não travar a cada troca de música."
PACOTES=()

instalar() {
    copiar_extensao mpris-debounce@local
    ativar_extensao mpris-debounce@local
    verde "  ✓ Mouse sem travar ao trocar de música instalado"
}

desinstalar() {
    remover_extensao mpris-debounce@local
    verde "  ✓ Mouse sem travar ao trocar de música removido"
}
