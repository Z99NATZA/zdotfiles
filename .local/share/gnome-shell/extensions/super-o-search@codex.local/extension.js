import Clutter from 'gi://Clutter';
import GLib from 'gi://GLib';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';

import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';

const KEYBINDING = 'open-search';

// XKB physical keycodes: independent of the active US/Thai layout.
const WINDOW_STEPS = new Map([
    [44, 1],  // J: next window
    [45, -1], // K: previous window
]);
const SEARCH_KEY = 31; // I

export default class SuperOSearchExtension extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._mode = 'search';
        this._enterHeld = false;
        this._focusSourceId = 0;
        this._initialWindow = null;

        this._capturedEventId = global.stage.connect(
            'captured-event',
            (actor, event) => this._onCapturedEvent(event)
        );

        this._overviewHiddenId = Main.overview.connect(
            'hidden',
            () => {
                this._cancelPendingFocus();
                this._mode = 'search';
                this._initialWindow = null;
            }
        );

        this._overviewShownId = Main.overview.connect('shown', () => {
            if (this._mode === 'windows' && !this._focusedPreview())
                this._selectInitialWindow();
        });

        Main.wm.addKeybinding(
            KEYBINDING,
            this._settings,
            Meta.KeyBindingFlags.IGNORE_AUTOREPEAT,
            Shell.ActionMode.NORMAL | Shell.ActionMode.OVERVIEW,
            () => {
                if (Main.overview.visible) {
                    Main.overview.hide();
                } else {
                    this._initialWindow = global.display.focus_window;
                    this._mode = 'windows';
                    this._enterHeld = false;
                    Main.overview.show();
                    this._focusWindows();
                }
            }
        );
    }

    _onCapturedEvent(event) {
        if (event.type() !== Clutter.EventType.KEY_PRESS &&
            event.type() !== Clutter.EventType.KEY_RELEASE)
            return Clutter.EVENT_PROPAGATE;
        const symbol = event.get_key_symbol();
        const isEnter = symbol === Clutter.KEY_Return ||
            symbol === Clutter.KEY_KP_Enter;
        if (event.type() === Clutter.EventType.KEY_RELEASE) {
            if (isEnter)
                this._enterHeld = false;
            return Clutter.EVENT_PROPAGATE;
        }

        if (event.type() !== Clutter.EventType.KEY_PRESS ||
            !Main.overview.visibleTarget || Main.modalCount > 1)
            return Clutter.EVENT_PROPAGATE;

        if (symbol === Clutter.KEY_Escape) {
            Main.overview.hide();
            return Clutter.EVENT_STOP;
        }

        // Leave modified shortcuts to GNOME; Caps Lock does not affect navigation.
        const modifiers = Clutter.ModifierType.CONTROL_MASK |
            Clutter.ModifierType.MOD1_MASK | Clutter.ModifierType.SUPER_MASK;
        if (event.get_state() & modifiers)
            return Clutter.EVENT_PROPAGATE;

        const focus = global.stage.key_focus;
        const entry = Main.overview.searchEntry;
        if (focus && (focus === entry || entry.contains(focus)))
            this._mode = 'search';
        else if (this._previews().some(p => p === focus || p.contains(focus)))
            this._mode = 'windows';

        if (isEnter) {
            // A held Enter must not select and immediately open a window.
            if (this._enterHeld)
                return Clutter.EVENT_STOP;
            this._enterHeld = true;
            if (this._mode === 'search') {
                if (!this._activateFirstSearchApp())
                    this._focusWindows();
            } else {
                const preview = this._focusedPreview();
                if (preview)
                    preview.emit('selected', event.get_time());
                else
                    this._selectInitialWindow();
            }
            return Clutter.EVENT_STOP;
        }

        if (this._mode === 'windows') {
            const code = event.get_key_code();
            if (code === SEARCH_KEY) {
                this._cancelPendingFocus();
                this._mode = 'search';
                Main.overview.focusSearch();
                return Clutter.EVENT_STOP;
            }

            const step = WINDOW_STEPS.get(code);
            if (step !== undefined) {
                this._cycleFocus(step);
                return Clutter.EVENT_STOP;
            }

            const direction = new Map([
                [Clutter.KEY_Left, [-1, 0]], [Clutter.KEY_Down, [0, 1]],
                [Clutter.KEY_Up, [0, -1]], [Clutter.KEY_Right, [1, 0]],
            ]).get(symbol);
            if (direction) {
                this._moveFocus(...direction);
                return Clutter.EVENT_STOP;
            }

            // Window mode enters search explicitly with I, never by typing.
            if (event.get_key_unicode())
                return Clutter.EVENT_STOP;
        }

        return Clutter.EVENT_PROPAGATE;
    }

    _activateFirstSearchApp() {
        const query = Main.overview.searchEntry.get_text().trim();
        if (!query)
            return false;

        const results = Main.overview._overview.controls._searchController._searchResults;
        const provider = results._providers.find(p => p.id === 'applications');
        const display = provider?.display;
        // Search updates asynchronously; never activate an old query's result.
        if (!display?.visible || results._startingSearch || provider.searchInProgress ||
            results.terms.join(' ') !== query.split(/\s+/).join(' ') ||
            display._terms.join(' ') !== results.terms.join(' '))
            return false;

        const first = display.getFirstResult();
        // The applications provider also returns system actions, such as logout.
        if (!first?.app)
            return false;

        first.activate();
        return true;
    }

    _previews() {
        const display = Main.overview._overview.controls._workspacesDisplay;
        return display._workspacesViews.flatMap(view =>
            view.getActiveWorkspace()?._windows ?? []
        ).filter(preview => preview.mapped && !preview.inDrag);
    }

    _focusedPreview() {
        const focus = global.stage.key_focus;
        return this._previews().find(p => p === focus || (focus && p.contains(focus)));
    }

    _selectInitialWindow() {
        const previews = this._previews();
        const preview = previews.find(p => p.metaWindow === this._initialWindow) ??
            previews[0];
        preview?.grab_key_focus();
    }

    _focusWindows() {
        this._mode = 'windows';
        this._cancelPendingFocus();
        const controls = Main.overview._overview.controls;
        controls._searchController.reset();
        controls.dash.showAppsButton.checked = false;
        this._selectInitialWindow();
        // Search results fade out before the window picker becomes visible.
        this._focusSourceId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 250, () => {
            this._focusSourceId = 0;
            if (Main.overview.visibleTarget && this._mode === 'windows' &&
                !this._focusedPreview())
                this._selectInitialWindow();
            return GLib.SOURCE_REMOVE;
        });
    }

    _cycleFocus(step) {
        const previews = this._previews();
        if (!previews.length)
            return;

        const index = previews.indexOf(this._focusedPreview());
        if (index < 0) {
            this._selectInitialWindow();
            return;
        }

        const next = (index + step + previews.length) % previews.length;
        previews[next].grab_key_focus();
    }

    _moveFocus(dx, dy) {
        const current = this._focusedPreview();
        if (!current) {
            this._selectInitialWindow();
            return;
        }
        const center = preview => {
            const [x, y] = preview.get_transformed_position();
            const [width, height] = preview.get_transformed_size();
            return [x + width / 2, y + height / 2];
        };
        const [x, y] = center(current);
        let next = null;
        let best = Infinity;
        for (const preview of this._previews()) {
            if (preview === current)
                continue;
            const [px, py] = center(preview);
            const forward = (px - x) * dx + (py - y) * dy;
            if (forward <= 1)
                continue;
            const sideways = Math.abs((px - x) * dy - (py - y) * dx);
            const score = Math.hypot(forward, sideways) + sideways * 2;
            if (score < best) {
                best = score;
                next = preview;
            }
        }
        next?.grab_key_focus();
    }

    _cancelPendingFocus() {
        if (this._focusSourceId) {
            GLib.source_remove(this._focusSourceId);
            this._focusSourceId = 0;
        }
    }

    disable() {
        this._cancelPendingFocus();
        Main.wm.removeKeybinding(KEYBINDING);

        if (this._capturedEventId) {
            global.stage.disconnect(this._capturedEventId);
            this._capturedEventId = 0;
        }

        if (this._overviewHiddenId) {
            Main.overview.disconnect(this._overviewHiddenId);
            this._overviewHiddenId = 0;
        }

        if (this._overviewShownId) {
            Main.overview.disconnect(this._overviewShownId);
            this._overviewShownId = 0;
        }

        this._mode = 'search';
        this._enterHeld = false;
        this._initialWindow = null;
        this._settings = null;
    }
}
