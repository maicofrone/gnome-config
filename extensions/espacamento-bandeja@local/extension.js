import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

// Aplica o espaçamento escolhido em cada botão da parte direita da barra,
// inclusive nos que aparecem depois (ícones de apps como o Dropbox).
export default class EspacamentoBandeja extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._box = Main.panel._rightBox;
        this._apply = () => {
            const p = this._settings.get_int('padding');
            const style = `-natural-hpadding: ${p}px; -minimum-hpadding: ${Math.floor(p / 2)}px;`;
            for (const container of this._box.get_children())
                container.get_first_child()?.set_style(style);
        };
        this._settingsId = this._settings.connect('changed::padding', this._apply);
        this._childId = this._box.connect('child-added', this._apply);
        this._apply();
    }

    disable() {
        this._settings.disconnect(this._settingsId);
        this._box.disconnect(this._childId);
        for (const container of this._box.get_children())
            container.get_first_child()?.set_style(null);
        this._settings = this._box = this._apply = null;
    }
}
