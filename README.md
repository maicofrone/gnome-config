# gnome-config

Minhas personalizações do GNOME (CachyOS / Arch), prontas para reinstalar depois de formatar.

O motivo de cada ajuste (e como resolver de novo se o problema voltar) está em **[HISTORICO.md](HISTORICO.md)**.

## Instalar

```bash
git clone git@github.com:maicofrone/gnome-config.git
cd gnome-config
./install.sh
```

O instalador mostra a lista de itens e pergunta:

```
  1) Instalar tudo
  2) Escolher item por item
  0) Cancelar
```

Em **"Escolher item por item"**, ele pergunta sim/não para cada um. Depois instala os pacotes que faltarem com o `pacman` e mostra um resumo no fim.

| Opção | O que faz |
|---|---|
| `./install.sh --tudo` | instala tudo sem perguntar |
| `./install.sh --sem-pacotes` | não instala pacotes do sistema |

Se instalou extensões, **saia da sessão e entre de novo** para o GNOME carregá-las.

## Itens disponíveis

| Item | O que faz |
|---|---|
| **Extensão: Ocultar indicadores** | Esconde da barra os ícones de Modo de energia (Performance) e Luz noturna. Os botões continuam no menu rápido. |
| **Extensão: Apps em segundo plano no menu** | Tira da barra os ícones de apps (Claude, Dropbox, Cachy-Update…) e os lista num botão **"Apps"** no menu rápido. |
| **Extensão: Botão do firewall** | Botão **"Firewall"** no menu rápido para ligar e desligar o ufw. **Desligar pede senha; ligar não**, mostra um escudo cortado na barra enquanto o firewall estiver desligado e **o firewall sempre volta ligado ao reiniciar o PC ou ao entrar na sessão**. |
| **Microfone: bloquear apps de mudar o volume** | Regra do PipeWire que impede apps baseados no Chrome (Claude, Vivaldi, Brave…) de baixar o microfone sozinhos, mais o app **Bloqueio do microfone** para editar a lista. |
| **Firewall: liberar KDE Connect** | Instala o KDE Connect e abre as portas 1714-1764 (TCP/UDP) no firewall (ufw ou firewalld). |
| **Firewall: liberar LocalSend** | Instala o LocalSend e abre a porta 53317 (TCP/UDP). |
| **Firewall: liberar OTA do ESP32** | Libera o upload OTA do ArduinoOTA/espota (Arduino IDE e PlatformIO): TCP 10000-60000, que é por onde o ESP32 se conecta de volta ao PC, mais o mDNS (5353/udp) para o ESP aparecer na rede. **Só para a rede local.** |

Os itens de firewall pedem a senha do `sudo`.

## Desinstalar

```bash
./uninstall.sh          # menu: remover tudo ou escolher
./uninstall.sh --tudo
```

Não remove pacotes do sistema.

## Salvar mudanças antes de enviar ao GitHub

Se você mudar algo no computador (por exemplo, bloquear um app novo no **Bloqueio do microfone**):

```bash
./salvar-alteracoes.sh
git add -A && git commit -m "Atualiza configurações" && git push
```

## Adicionar um item novo

Cada item é um arquivo em `modulos/`. O número no começo do nome define a ordem. Copie um módulo parecido e ajuste:

```bash
TITULO="Firewall: liberar Syncthing"
DESCRICAO="Abre as portas do Syncthing."
PACOTES=(syncthing)          # pacotes do pacman que o item precisa

instalar()    { liberar_portas "Syncthing" "22000"; }
desinstalar() { fechar_portas  "Syncthing" "22000"; }
```

Funções prontas em `lib.sh`: `copiar_extensao`, `ativar_extensao`, `remover_extensao`, `liberar_portas` / `fechar_portas` (qualquer rede), `liberar_portas_lan` / `fechar_portas_lan` (só rede local: 192.168.x, 10.x, 172.16-31.x), `verde`, `amarelo`.

## Estrutura

```
install.sh / uninstall.sh / salvar-alteracoes.sh
HISTORICO.md           o que foi feito e por quê
lib.sh                 funções compartilhadas e o menu
modulos/               um arquivo por item instalável
extensions/            código das extensões do GNOME
apps/                  app Bloqueio do microfone
config/pipewire/       regra do microfone
```

## Observações

- Reiniciar o som (ao instalar ou mudar a regra do microfone) faz apps como o Claude e os navegadores perderem o microfone até serem fechados e abertos de novo.
- As extensões declaram suporte ao GNOME 45 a 51. Em versões novas, pode ser preciso adicionar a versão em `metadata.json`.
