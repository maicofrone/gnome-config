import GObject from 'gi://GObject';
import GLib from 'gi://GLib';
import St from 'gi://St';
import Clutter from 'gi://Clutter';

import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {QuickMenuToggle, SystemIndicator} from 'resource:///org/gnome/shell/ui/quickSettings.js';

const PREFIXO = 'appindicator-';

function nomeDoApp(btn) {
    const ind = btn._indicator;
    return ind?._appInfo?.get_display_name?.() || ind?.title || ind?.id ||
        btn.get_accessible_name?.() || 'App';
}

function iconeDoApp(btn) {
    return btn._indicator?._appInfo?.get_icon?.() ?? btn.icon?.gicon ?? null;
}

const AppsToggle = GObject.registerClass(
class AppsToggle extends QuickMenuToggle {
    _init() {
        super._init({
            title: 'Apps',
            iconName: 'view-app-grid-symbolic',
            toggleMode: false,
        });
        this.menu.setHeader('view-app-grid-symbolic', 'Apps em segundo plano');
        this._lista = new PopupMenu.PopupMenuSection();
        this.menu.addMenuItem(this._lista);
        this.connect('clicked', () => this.menu.open());
    }

    atualizar(botoes, aoEscolher) {
        this._lista.removeAll();
        for (const btn of botoes) {
            const item = new PopupMenu.PopupImageMenuItem(nomeDoApp(btn), null);
            const gicon = iconeDoApp(btn);
            if (gicon)
                item.setIcon(gicon);
            item.connect('activate', () => aoEscolher(btn));
            this._lista.addMenuItem(item);
        }
        const n = botoes.length;
        this.subtitle = n === 0 ? 'Nenhum' : n === 1 ? '1 app' : `${n} apps`;
        this.visible = n > 0;
    }
});

const Indicador = GObject.registerClass(
class Indicador extends SystemIndicator {
    _init() {
        super._init();
        this.toggle = new AppsToggle();
        this.quickSettingsItems.push(this.toggle);
    }
});

export default class AppsNoMenu {
    enable() {
        this._botoes = new Map(); // btn -> {container, ids}
        this._indicador = new Indicador();
        Main.panel.statusArea.quickSettings.addExternalIndicator(this._indicador);

        this._caixas = [Main.panel._leftBox, Main.panel._centerBox, Main.panel._rightBox];
        this._idsCaixas = this._caixas.map(c =>
            c.connect('child-added', () => this._agendarVarredura()));
        this._varrer();
    }

    _agendarVarredura() {
        if (this._idleVarrer)
            return;
        this._idleVarrer = GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
            this._idleVarrer = 0;
            this._varrer();
            return GLib.SOURCE_REMOVE;
        });
    }

    _varrer() {
        const area = Main.panel.statusArea;
        for (const [chave, btn] of Object.entries(area)) {
            if (!chave.startsWith(PREFIXO) || !btn || this._botoes.has(btn))
                continue;
            this._adotar(btn);
        }
        this._sincronizar();
    }

    _adotar(btn) {
        const container = btn.container ?? btn.get_parent();
        container?.hide();
        const ids = [
            [btn, btn.connect('destroy', () => {
                this._botoes.delete(btn);
                this._sincronizar();
            })],
            [btn, btn.connect('notify::visible', () => this._sincronizar())],
        ];
        if (container) {
            ids.push([container, container.connect('notify::visible', () => {
                const info = this._botoes.get(btn);
                if (container.visible && info && !info.aberto)
                    container.hide();
            })]);
        }
        this._botoes.set(btn, {container, ids, aberto: false});
    }

    _sincronizar() {
        // Mostra só os apps que estariam visíveis na barra
        const visiveis = [...this._botoes.keys()].filter(b => b.visible);
        visiveis.sort((a, b) => nomeDoApp(a).localeCompare(nomeDoApp(b)));
        this._indicador.toggle.atualizar(visiveis, btn => this._abrir(btn));
    }

    _abrir(btn) {
        const info = this._botoes.get(btn);
        if (!info)
            return;
        Main.panel.statusArea.quickSettings.menu.close();

        // Mostra o ícone só enquanto o menu do app estiver aberto
        info.aberto = true;
        info.container?.show();

        const esconder = () => {
            info.aberto = false;
            if (this._botoes.has(btn))
                info.container?.hide();
        };

        const menu = btn.menu;
        const temMenu = menu && typeof menu.open === 'function' &&
            (btn._menuClient || (menu.numMenuItems ?? 0) > 0);
        const ativavel = typeof btn._indicator?.open === 'function';

        GLib.timeout_add(GLib.PRIORITY_DEFAULT, 150, () => {
            if (!this._botoes.has(btn))
                return GLib.SOURCE_REMOVE;
            if (temMenu) {
                const id = menu.connect('open-state-changed', (m, aberto) => {
                    if (!aberto) {
                        menu.disconnect(id);
                        esconder();
                    }
                });
                menu.open();
            } else if (ativavel) {
                // App sem menu: aciona como um clique no ícone
                const [x, y] = btn.get_transformed_position();
                btn._indicator.open(x, y, Clutter.get_current_event_time());
                esconder();
            } else {
                // Ícone antigo (bandeja legada): deixa à mostra por alguns
                // segundos para você clicar nele na barra
                GLib.timeout_add_seconds(GLib.PRIORITY_DEFAULT, 8, () => {
                    esconder();
                    return GLib.SOURCE_REMOVE;
                });
            }
            return GLib.SOURCE_REMOVE;
        });
    }

    disable() {
        if (this._idleVarrer) {
            GLib.source_remove(this._idleVarrer);
            this._idleVarrer = 0;
        }
        this._caixas?.forEach((c, i) => c.disconnect(this._idsCaixas[i]));
        for (const [btn, info] of this._botoes) {
            for (const [obj, id] of info.ids)
                obj.disconnect(id);
            if (btn.visible)
                info.container?.show();
        }
        this._botoes.clear();
        this._indicador.quickSettingsItems.forEach(i => i.destroy());
        this._indicador.destroy();
        this._indicador = null;
    }
}
