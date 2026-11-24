import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const ALVOS = ['_powerProfiles', '_nightLight'];

export default class OcultarIndicadores {
    enable() {
        this._ligacoes = [];
        const qs = Main.panel.statusArea.quickSettings;
        const tentar = () => {
            for (const nome of ALVOS) {
                const ind = qs[nome]?._indicator;
                if (!ind || this._ligacoes.some(([i]) => i === ind))
                    continue;
                ind.hide();
                const id = ind.connect('notify::visible', () => {
                    if (ind.visible)
                        ind.hide();
                });
                this._ligacoes.push([ind, id]);
            }
            return this._ligacoes.length < ALVOS.length;
        };
        // Os indicadores podem ser criados depois do carregamento da extensão
        if (tentar())
            this._idle = setInterval(() => { if (!tentar()) this._parar(); }, 500);
    }

    _parar() {
        if (this._idle) {
            clearInterval(this._idle);
            this._idle = null;
        }
    }

    disable() {
        this._parar();
        for (const [ind, id] of this._ligacoes ?? [])
            ind.disconnect(id);
        this._ligacoes = [];
        // Deixa o GNOME recalcular a visibilidade original
        const qs = Main.panel.statusArea.quickSettings;
        qs._nightLight?._sync?.();
        qs._powerProfiles?._powerProfilesToggle?.notify('checked');
    }
}
