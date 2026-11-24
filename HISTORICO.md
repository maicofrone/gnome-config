# Histórico: problemas resolvidos e por quê

Registro do que foi ajustado neste sistema (CachyOS + GNOME 51), com a causa de cada problema. Serve para lembrar o motivo de cada item do `install.sh` e para resolver de novo se algo voltar a acontecer.

---

## 2026-11-23: Barra superior mais limpa

### Ícones de apps (Claude, Dropbox, Cachy-Update) sempre na barra
- **Causa:** a extensão AppIndicator coloca o ícone de cada app em segundo plano direto na barra, e não tem opção para agrupar.
- **Solução:** extensão própria **`apps-no-menu@local`**. Ela esconde os ícones e cria um botão **"Apps"** no menu rápido (Wi-Fi/volume). Ao clicar num app, o menu dele abre normalmente e o ícone aparece só enquanto o menu está aberto.

### Ícones de "Performance" e "Luz noturna" aparecendo na barra
- **Causa:** o GNOME mostra esses ícones sempre que o modo não é o "Equilibrado" ou quando a Luz noturna está ativa.
- **Solução:** extensão **`ocultar-indicadores@local`**. Ela esconde só os ícones da barra, e os botões continuam no menu rápido.

### Espaçamento entre os ícones
- Extensão **`espacamento-bandeja@local`** (já existia), com o espaçamento em 6 px.

---

## 2026-11-23/24: Microfone baixando de volume sozinho

- **Sintoma:** o microfone voltava em ~75% depois de reiniciar e também caía durante o uso (de 100% para 53% sem mexer).
- **Causa:** apps baseados no Chrome (Claude, Vivaldi, Brave, Electron) têm um **ajuste automático de ganho** (WebRTC AGC). Eles baixam o volume do microfone no sistema, e o WirePlumber salva esse valor.
- **1ª tentativa (descartada):** um serviço em segundo plano que devolvia o volume para 100%. Funcionava, mas deixava um programa rodando o tempo todo.
- **Solução final:** regra do PipeWire `block-source-volume` em
  `~/.config/pipewire/pipewire-pulse.conf.d/10-bloquear-volume-microfone.conf`.
  Os apps da lista continuam usando o microfone, mas recebem "Access denied" ao tentar mudar o volume. Você continua mudando o volume normalmente pelo GNOME.
- **App "Bloqueio do microfone":** janela para ver, adicionar e remover apps da lista sem editar o arquivo.
- **Atenção:** cada mudança na lista reinicia o `pipewire-pulse`, e apps abertos (Claude, navegadores) **perdem o microfone** ("Nenhum microfone encontrado") até serem fechados e abertos de novo.

---

## 2026-11-24: KDE Connect não conectava com o celular

- **Causa:** o firewall **ufw** do CachyOS vem ativo, com a política de entrada `DROP`, e bloqueia as portas que o KDE Connect usa.
- **Solução:** liberar **1714-1764 TCP/UDP**. Item **"Firewall: liberar KDE Connect"**.
- **Dica:** celular e PC precisam estar na mesma rede. Se o PC não aparecer, use "Adicionar dispositivo por IP" no app do celular.

## 2026-11-24: LocalSend

- Usa a porta **53317 TCP/UDP**. Item **"Firewall: liberar LocalSend"**, opcional.

## 2026-11-24: Upload OTA no ESP32

- **Causa:** no ArduinoOTA/espota (Arduino IDE e PlatformIO), o PC avisa o ESP32 (porta 3232) e o **ESP32 se conecta de volta ao PC** numa porta TCP sorteada entre **10000 e 60000**. O firewall bloqueia essa conexão de volta.
- **Solução:** liberar TCP 10000-60000 e o mDNS (5353/udp, para o ESP aparecer em "Portas de rede"), **só para a rede local** (192.168.0.0/16, 10.0.0.0/8, 172.16.0.0/12). Item **"Firewall: liberar OTA do ESP32"**.
- O OTA do ESPHome e o OTA pelo navegador (ElegantOTA) não precisam disso, porque neles é o PC que se conecta ao ESP.

## 2026-11-24: Botão para ligar/desligar o firewall

- **Motivo:** às vezes é preciso desligar o firewall rapidamente (testes, um app que não conecta) sem abrir o terminal.
- **Solução:** extensão **`firewall-toggle@local`**, um botão **"Firewall"** no menu rápido.
  - O estado vem de `/etc/ufw/ufw.conf` (`ENABLED=yes/no`), que dá para ler sem senha.
  - Ligar/desligar usa `pkexec ufw enable/disable`, e o GNOME pede a senha de administrador.
  - Enquanto o firewall estiver **desligado**, aparece na barra um escudo cortado por uma faixa (ícone próprio, monocromático, em `icons/`), para você não esquecer de religar.
  - As regras liberadas (KDE Connect, ESP32 etc.) continuam salvas e voltam ao religar.
- **Sempre volta ligado ao reiniciar:** por padrão o `ufw disable` é permanente e continuaria desligado depois do boot. Um drop-in do systemd em `/etc/systemd/system/ufw.service.d/religar-no-boot.conf` muda `ENABLED=yes` no `ufw.conf` antes do ufw iniciar. Assim, desligar pelo botão vale só até o próximo reinício.

---

## Ajustes manuais (não automatizados)

### Programas que iniciam com o computador
- **Seus apps:** app **Ajustes** (GNOME Tweaks) → **Aplicativos de inicialização**. Ficam em `~/.config/autostart/`.
- **Apps do sistema** (Cachy-Update, KDE Connect, localsearch, avisos do Limine) ficam em `/etc/xdg/autostart/` e não aparecem no Ajustes. Para desligar um deles só para o seu usuário:
  ```bash
  cp /etc/xdg/autostart/NOME.desktop ~/.config/autostart/ && echo "Hidden=true" >> ~/.config/autostart/NOME.desktop
  ```
- **Cachy-Update:** além do ícone, existe o `arch-update.timer`, que verifica atualizações 2 min após ligar e depois 1x por dia. Ele só avisa e não instala nada. Para desligar:
  ```bash
  systemctl --user disable --now arch-update.timer
  ```

### Ver as regras do firewall
```bash
sudo ufw status numbered
```
