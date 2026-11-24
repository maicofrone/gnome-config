# gnome-config

Minhas personalizações do GNOME (CachyOS / Arch), prontas para reinstalar depois de formatar.

## O que tem aqui

| Item | Tipo | O que faz |
|---|---|---|
| `extensions/espacamento-bandeja@local` | Extensão GNOME | Ajusta a distância entre os ícones do lado direito da barra superior. |
| `extensions/ocultar-indicadores@local` | Extensão GNOME | Esconde da barra os ícones de **Modo de energia (Performance)** e **Luz noturna**. Os botões continuam no menu rápido. |
| `extensions/apps-no-menu@local` | Extensão GNOME | Tira da barra os ícones de apps (Claude, Dropbox, Cachy-Update…) e os lista num botão **"Apps"** dentro do menu rápido (Wi-Fi/volume). |
| `apps/bloqueio-microfone` | App (Python + GTK4) | Janela para ver e editar quais apps **não podem mudar o volume do microfone**. |
| `config/pipewire/…/10-bloquear-volume-microfone.conf` | Configuração do PipeWire | A lista de apps bloqueados. Impede que apps baseados no Chrome (Claude, Vivaldi, Brave…) baixem o microfone sozinhos. |

## Instalar

```bash
git clone <url-deste-repositorio> gnome-config
cd gnome-config
./install.sh
```

Depois **saia da sessão e entre de novo** para o GNOME carregar as extensões.

O `install.sh`:
1. instala os pacotes necessários com `pacman`, pedindo a senha do `sudo` (`gnome-shell-extension-appindicator`, `python-gobject`, `libadwaita`…). Para pular essa parte, use `./install.sh --sem-pacotes`;
2. copia e ativa as extensões e define o espaçamento da bandeja (6 px);
3. instala o app **Bloqueio do microfone** no menu de aplicativos;
4. copia a regra do microfone e reinicia o som, se a regra mudou.

## Salvar mudanças antes de enviar ao GitHub

Se você mudar algo no computador (por exemplo, bloquear um app novo pelo app **Bloqueio do microfone**), rode:

```bash
./salvar-alteracoes.sh
git add -A && git commit -m "Atualiza configurações" && git push
```

## Desinstalar

```bash
./uninstall.sh
```

## Observações

- Reiniciar o som (ao instalar ou ao mudar a lista de bloqueio) faz apps como o Claude e os navegadores perderem o microfone até serem fechados e abertos de novo.
- As extensões declaram suporte ao GNOME 45 a 51. Em versões novas do GNOME, pode ser preciso adicionar a versão em `metadata.json`.
