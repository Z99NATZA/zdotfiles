import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

export default class HideTopBarExtension extends Extension {
    enable() {
        this._panelBox = Main.layoutManager.panelBox;
        this._wasVisible = this._panelBox.visible;
        this._panelData = Main.layoutManager._trackedActors.find(
            data => data.actor === this._panelBox);
        if (this._panelData) {
            this._affectedStruts = this._panelData.affectsStruts;
            // GNOME reserves struts even when the tracked actor is hidden.
            this._panelData.affectsStruts = false;
            Main.layoutManager._queueUpdateRegions();
        }
        this._visibilityId = this._panelBox.connect('notify::visible', () => {
            if (this._panelBox.visible)
                this._panelBox.hide();
        });
        this._panelBox.hide();
    }

    disable() {
        this._panelBox.disconnect(this._visibilityId);
        this._visibilityId = 0;
        if (this._panelData) {
            this._panelData.affectsStruts = this._affectedStruts;
            Main.layoutManager._queueUpdateRegions();
            this._panelData = null;
        }
        this._panelBox.visible = this._wasVisible;
        this._panelBox = null;
    }
}
