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

### Espaçamento entre os ícones (removido)
- A extensão `espacamento-bandeja@local` ajustava a distância entre os ícones da barra. Foi **removida em 2026-11-24** porque, com os ícones dos apps agrupados no botão "Apps", ela deixou de ser útil.

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
- **2026-11-24, correção:** o firewall não religou num reinício porque a regra acima nunca tinha sido instalada (dependia de rodar um comando com `sudo` à parte). Agora a própria extensão instala a regra na primeira vez que você desliga o firewall, com a mesma senha. O arquivo da regra fica dentro da extensão (`firewall-toggle@local/religar-no-boot.conf`).
- **2026-11-24, ligar sem senha:** regra do polkit `/etc/polkit-1/rules.d/49-firewall-toggle.rules` que permite **só** o comando exato `/usr/bin/ufw --force enable`, para o usuário do grupo `wheel` na sessão local ativa. Desligar continua pedindo senha (ligar só aumenta a proteção, desligar não).
  - A extensão instala as duas regras (systemd + polkit) na primeira ação que pedir senha. Como a pasta do polkit não pode ser lida sem root, ela grava um marcador de versão em `/usr/local/share/firewall-toggle/versao` para saber se já instalou.
- **2026-11-24, religar também no login:** a regra do systemd só age num **reinício de verdade**. Sair da sessão e entrar de novo não reinicia o ufw, então o firewall continuava desligado. Agora a extensão também religa o firewall (sem senha) **uma vez por login**. No desbloqueio de tela ela não religa: o GNOME chama `enable()` a cada desbloqueio, mas uma variável que vive enquanto a sessão estiver aberta evita repetir.

## 2026-11-24: Saídas de áudio sobrando na lista

- **Sintoma:** a lista de saídas de som mostrava 6 opções, mas só são usadas duas: a **Analog Output do HyperX Cloud Revolver S** e a **Line Out** da placa-mãe.
- **Causa:** o PC tem 3 placas de áudio (headset HyperX USB, placa-mãe Starship/Matisse e a placa de vídeo NVIDIA AD106M), e o GNOME lista todas as saídas que cada uma oferece, mesmo as sem nada ligado.
  - As duas **HDMI / DisplayPort** são o som da placa de vídeo para o monitor. Colocar o perfil dela em "Desligado" no `pavucontrol` **não adianta**: ela já estava desligada e o GNOME continuava mostrando as saídas.
  - As duas **S/PDIF** (digitais) fazem parte do headset e da placa-mãe, então não dá para desligar a placa inteira.
- **Solução:** uma regra do WirePlumber em `~/.config/wireplumber/wireplumber.conf.d/50-saidas-de-audio.conf`. Item **"Áudio: escolher as saídas"**.
  - O WirePlumber não sabe esconder **uma saída** sozinha, só mexer na **placa inteira**. Por isso há dois jeitos:
    - nenhuma saída da placa escolhida → `device.disabled = true` (a placa some; no caso da NVIDIA só o áudio some, o vídeo não é afetado);
    - só a analógica escolhida → `device.profile-set = "analog-only.conf"`, um perfil que já vem com o sistema (`/usr/share/alsa-card-profile/mixer/profile-sets/`) e tira as saídas digitais e HDMI daquela placa. Os microfones continuam funcionando.
  - Não dá para deixar só a digital e esconder a analógica da mesma placa: nesse caso a placa fica como está.
  - **Atenção:** a propriedade certa é `device.profile-set`. A `api.acp.profile-set` é aceita sem erro, mas não faz nada.
- **Escolha na instalação:** o item roda `apps/saidas-de-audio/escolher-saidas`. Ele tira a regra por um instante, reinicia o WirePlumber para enxergar todas as saídas, mostra a lista numerada e pergunta quais devem aparecer (Enter mantém a escolha anterior). Se uma placa com microfone (como o headset) ficar sem nenhuma saída, ele pergunta se o microfone deve ser desativado junto. A escolha fica anotada no começo do arquivo (linhas `# manter:`).
  - Com `./install.sh --tudo` ou sem terminal, não pergunta: usa a escolha que já está no PC ou, se não houver, a salva no gnome-config (`config/wireplumber/`).
  - A primeira versão do item (2026-11-24) tinha duas regras fixas, `51-desativar-hdmi-nvidia.conf` e `52-somente-analogico.conf`. O item novo apaga essas duas se encontrar.
- **Cuidado ao testar:** reiniciar o WirePlumber muitas vezes seguidas faz o systemd bloquear o serviço ("start of the service was attempted too often") e o **som para de vez**. O script roda `systemctl --user reset-failed wireplumber` antes de cada reinício. Se acontecer mesmo assim:
  ```bash
  systemctl --user reset-failed wireplumber && systemctl --user start wireplumber
  ```
- A regra usa o nome exato de cada placa. Se trocar o headset, a placa de vídeo ou a placa-mãe, os nomes mudam e a regra deixa de valer (sem quebrar nada): é só rodar o item de novo. Veja os nomes atuais com `pactl list cards short`.
- **Para desfazer:** `./uninstall.sh` e escolha o item, ou apague o arquivo e rode `systemctl --user restart wireplumber`.

---

## 2026-11-26: Mouse travando ao passar música no YouTube Music

- **Sintoma:** ao trocar de música no YouTube Music (no Vivaldi), o mouse dava **duas travadinhas**. Desativar e reativar a extensão Quick Settings Audio Panel melhorava, mas a travada voltava depois de um tempo.
- **Causa:** o Vivaldi (e o Chrome) mandam uma **rajada de avisos de mídia (MPRIS)** a cada troca de faixa. Numa gravação de 90 s com `dbus-monitor` foram 385 avisos, até 26 no mesmo segundo, e quase todos com a capa do álbum num **arquivo temporário novo** (43 arquivos diferentes). O player de mídia do GNOME (e o da Quick Settings Audio Panel, que usa o mesmo código) redesenhava a capa a cada aviso. No Wayland o `gnome-shell` também desenha o mouse, então cada redesenho trava o cursor. As duas travadinhas são a miniatura da capa e depois a versão grande. Como cada capa é um arquivo novo, o cache do GNOME vai crescendo e a travada piora com o tempo.
- **Alternativa descartada:** desligar `Hardware Media Key Handling` em `vivaldi://flags`. Resolve, mas o player some do painel e as teclas de mídia param de controlar o YouTube Music.
- **Solução:** extensão **`mpris-debounce@local`**. Ela troca o `MprisPlayer._updateState` do GNOME (`resource:///org/gnome/shell/ui/mpris.js`) por uma versão que espera **0,4 s sem avisos novos** (no máximo 1,2 s) e atualiza o player uma vez só, já com a capa final. Item **"Extensão: Mouse sem travar ao trocar de música"**.
  - O título e a capa no painel podem aparecer até ~1 s depois da troca. A música em si não atrasa.
  - Só foi testada no **GNOME 51**: ela mexe em funções internas do GNOME, que podem mudar de nome em versões novas. Se o GNOME atualizar e a travada voltar (ou a extensão der erro), confira se `MprisPlayer`, `_updateState` e `_onPlayerProxyReady` ainda existem em `ui/mpris.js`.
- **Para conferir as rajadas de novo:**
  ```bash
  dbus-monitor --session "type='signal',interface='org.freedesktop.DBus.Properties',path='/org/mpris/MediaPlayer2'"
  ```

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
