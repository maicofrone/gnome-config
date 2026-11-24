import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import GObject from 'gi://GObject';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {QuickToggle, SystemIndicator} from 'resource:///org/gnome/shell/ui/quickSettings.js';

// O ufw guarda se está ligado em /etc/ufw/ufw.conf (ENABLED=yes/no).
// Esse arquivo pode ser lido sem senha, então o estado aparece sempre.
const CONF = '/etc/ufw/ufw.conf';
const UFW = '/usr/bin/ufw';

// Ícone próprio (escudo cortado), monocromático como os ícones do GNOME
const PASTA = GLib.path_get_dirname(GLib.filename_from_uri(import.meta.url)[0]);
const ICONE_LIGADO = Gio.ThemedIcon.new('security-high-symbolic');
const ICONE_DESLIGADO = Gio.FileIcon.new(
    Gio.File.new_for_path(`${PASTA}/icons/firewall-desligado-symbolic.svg`));

function lerEstado() {
    try {
        const [, bytes] = GLib.file_get_contents(CONF);
        return /^\s*ENABLED\s*=\s*yes\b/m.test(new TextDecoder().decode(bytes));
    } catch {
        return null; // ufw não instalado
    }
}

function rodar(args) {
    return new Promise((resolve, reject) => {
        const proc = Gio.Subprocess.new(args,
            Gio.SubprocessFlags.STDOUT_SILENCE | Gio.SubprocessFlags.STDERR_SILENCE);
        proc.wait_async(null, (p, res) => {
            try {
                p.wait_finish(res);
                resolve(p.get_exit_status());
            } catch (e) {
                reject(e);
            }
        });
    });
}

const FirewallToggle = GObject.registerClass(
class FirewallToggle extends QuickToggle {
    _init(aoMudar) {
        super._init({
            title: 'Firewall',
            gicon: ICONE_LIGADO,
            toggleMode: false,
        });
        this._aoMudar = aoMudar;
        this._ocupado = false;
        this.connect('clicked', () => this._alternar().catch(logError));
    }

    mostrar(ligado) {
        this.checked = ligado === true;
        this.gicon = ligado === false ? ICONE_DESLIGADO : ICONE_LIGADO;
        if (!this._ocupado)
            this.subtitle = ligado === null ? 'ufw não instalado' : ligado ? 'Ativo' : 'Desativado';
        this.reactive = ligado !== null && !this._ocupado;
    }

    async _alternar() {
        const ligado = lerEstado();
        if (ligado === null || this._ocupado)
            return;
        this._ocupado = true;
        this.subtitle = ligado ? 'Desativando…' : 'Ativando…';
        this.reactive = false;
        Main.panel.statusArea.quickSettings.menu.close();

        try {
            // pkexec abre a janela de senha do GNOME
            const status = await rodar(['pkexec', UFW, ...(ligado ? ['disable'] : ['--force', 'enable'])]);
            if (status === 0)
                Main.notify('Firewall', ligado ? 'Firewall desativado.' : 'Firewall ativado.');
            else if (status !== 126 && status !== 127) // 126/127 = senha cancelada
                Main.notifyError('Firewall', `Não foi possível mudar o firewall (código ${status}).`);
        } finally {
            this._ocupado = false;
            this._aoMudar();
        }
    }
});

const Indicador = GObject.registerClass(
class Indicador extends SystemIndicator {
    _init() {
        super._init();
        // Ícone de alerta na barra, só enquanto o firewall estiver DESLIGADO
        this._icone = this._addIndicator();
        this._icone.gicon = ICONE_DESLIGADO;

        this.toggle = new FirewallToggle(() => this.atualizar());
        this.quickSettingsItems.push(this.toggle);

        // Atualiza sozinho se o ufw mudar por outro caminho (terminal, install.sh...)
        this._monitor = Gio.File.new_for_path(CONF).monitor_file(Gio.FileMonitorFlags.NONE, null);
        this._monitor.connect('changed', () => this.atualizar());
        this.atualizar();
    }

    atualizar() {
        const ligado = lerEstado();
        this._icone.visible = ligado === false;
        this.toggle.mostrar(ligado);
    }

    destroy() {
        this._monitor?.cancel();
        this._monitor = null;
        this.quickSettingsItems.forEach(i => i.destroy());
        super.destroy();
    }
});

export default class FirewallToggleExtension {
    enable() {
        this._indicador = new Indicador();
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicador);
    }

    disable() {
        this._indicador?.destroy();
        this._indicador = null;
    }
}
