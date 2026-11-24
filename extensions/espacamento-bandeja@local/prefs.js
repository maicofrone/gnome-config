import Adw from 'gi://Adw';
import Gio from 'gi://Gio';
import Gtk from 'gi://Gtk';
import {ExtensionPreferences} from 'resource:///org/gnome/Shell/Extensions/js/extensions/prefs.js';

export default class EspacamentoBandejaPrefs extends ExtensionPreferences {
    fillPreferencesWindow(window) {
        const settings = this.getSettings();
        const page = new Adw.PreferencesPage();
        const group = new Adw.PreferencesGroup({
            title: 'Distância entre os ícones',
            description: 'Espaço de cada lado dos ícones da direita da barra. O padrão do GNOME é 12.',
        });
        const row = new Adw.SpinRow({
            title: 'Espaçamento (px)',
            subtitle: 'Menor = ícones mais próximos',
            adjustment: new Gtk.Adjustment({lower: 0, upper: 20, step_increment: 1}),
        });
        settings.bind('padding', row, 'value', Gio.SettingsBindFlags.DEFAULT);
        group.add(row);
        page.add(group);
        window.add(page);
        window._settings = settings;
    }
}
