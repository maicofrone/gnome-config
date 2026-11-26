import GLib from 'gi://GLib';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import {MprisPlayer} from 'resource:///org/gnome/shell/ui/mpris.js';

// Espera este tempo sem novos avisos antes de atualizar a interface.
const DELAY_MS = 400;
// Mas nunca segura uma atualização por mais que isso.
const MAX_WAIT_MS = 1200;

export default class MprisDebounceExtension extends Extension {
    enable() {
        const proto = MprisPlayer.prototype;
        this._origUpdate = proto._updateState;
        this._origReady = proto._onPlayerProxyReady;
        this._origClose = proto._close;
        const origUpdate = this._origUpdate;
        const origClose = this._origClose;

        const flush = player => {
            if (player.__dbTimer) {
                GLib.source_remove(player.__dbTimer);
                player.__dbTimer = 0;
            }
            player.__dbFirst = 0;
            if (player._playerProxy && player._mprisProxy)
                origUpdate.call(player);
        };

        const debounced = function () {
            const now = GLib.get_monotonic_time() / 1000;
            if (!this.__dbFirst)
                this.__dbFirst = now;
            if (this.__dbTimer)
                GLib.source_remove(this.__dbTimer);
            const wait = Math.min(DELAY_MS, Math.max(0, MAX_WAIT_MS - (now - this.__dbFirst)));
            this.__dbTimer = GLib.timeout_add(GLib.PRIORITY_DEFAULT, wait, () => {
                this.__dbTimer = 0;
                flush(this);
                return GLib.SOURCE_REMOVE;
            });
        };
        this._debounced = debounced;

        // Novos players: conecta o sinal à versão agrupada.
        proto._onPlayerProxyReady = function () {
            this._playerProxy.connectObject(
                'g-properties-changed', () => debounced.call(this), this);
            origUpdate.call(this);
        };
        proto._updateState = debounced;
        proto._close = function () {
            if (this.__dbTimer) {
                GLib.source_remove(this.__dbTimer);
                this.__dbTimer = 0;
            }
            origClose.call(this);
        };
    }

    disable() {
        const proto = MprisPlayer.prototype;
        proto._updateState = this._origUpdate;
        proto._onPlayerProxyReady = this._origReady;
        proto._close = this._origClose;
        this._origUpdate = this._origReady = this._origClose = this._debounced = null;
    }
}
