TITULO="Firewall: liberar LocalSend"
DESCRICAO="Instala o LocalSend e abre a porta 53317 (TCP/UDP) para receber arquivos. Pede senha (sudo)."
PACOTES=(localsend)
PORTAS="53317"

instalar() {
    liberar_portas "LocalSend" "$PORTAS"
}

desinstalar() {
    fechar_portas "LocalSend" "$PORTAS"
}
