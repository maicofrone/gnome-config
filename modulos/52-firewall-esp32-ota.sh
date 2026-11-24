TITULO="Firewall: liberar OTA do ESP32"
DESCRICAO="Libera o upload OTA (ArduinoOTA/espota: Arduino IDE e PlatformIO) e a descoberta do ESP pela rede (mDNS). Só na rede local. Pede senha (sudo)."
PACOTES=()

# Como funciona o OTA do ArduinoOTA: o PC avisa o ESP32 (porta 3232) e o ESP32
# se conecta DE VOLTA no PC, numa porta TCP sorteada entre 10000 e 60000, para
# baixar o firmware. É essa conexão de volta que o firewall bloqueia.
# O mDNS (5353/udp) faz o ESP aparecer em "Portas de rede" na Arduino IDE.
PORTAS_OTA="10000:60000"
PORTA_MDNS="5353"

instalar() {
    liberar_portas_lan "ESP32 OTA" "$PORTAS_OTA" tcp
    liberar_portas_lan "mDNS (ESP32)" "$PORTA_MDNS" udp
}

desinstalar() {
    fechar_portas_lan "ESP32 OTA" "$PORTAS_OTA" tcp
    fechar_portas_lan "mDNS (ESP32)" "$PORTA_MDNS" udp
}
