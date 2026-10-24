'use strict';

// Exercise the shipped extension with Shell actors/apps stubbed, without a UI session.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

const Clutter = {
    EventType: {KEY_PRESS: 1, KEY_RELEASE: 2},
    KEY_Return: 'Return', KEY_KP_Enter: 'KP_Enter', KEY_Escape: 'Escape',
    ModifierType: {CONTROL_MASK: 1, MOD1_MASK: 2, SUPER_MASK: 4},
    EVENT_STOP: 'stop', EVENT_PROPAGATE: 'propagate',
};
const Shell = {AppState: {RUNNING: 1, STOPPED: 0}};

async function fixture() {
    const calls = [];
    function result(name, {actions = [], running = true, canOpen = false} = {}) {
        return {
            app: {
                app_info: {list_actions: () => actions},
                state: running ? Shell.AppState.RUNNING : Shell.AppState.STOPPED,
                can_open_new_window: () => canOpen,
                open_new_window: workspace => calls.push([name, 'new-window', workspace]),
            },
            activate: () => calls.push([name, 'activate']),
            animateLaunch: () => calls.push([name, 'animate']),
        };
    }
    const first = result('first');
    const selected = result('selected', {canOpen: true});
    const label = {get_parent: () => selected};
    const display = {
        visible: true,
        _terms: ['terminal'],
        contains: actor => [first, selected, label].includes(actor),
        getFirstResult: () => first,
    };
    const provider = {id: 'applications', display, searchInProgress: false};
    const results = {_providers: [provider], _startingSearch: false, terms: ['terminal']};
    const entry = {get_text: () => 'terminal', contains: () => false};
    const shellGlobal = {stage: {key_focus: entry}};
    const overview = {
        visibleTarget: true,
        searchEntry: entry,
        _overview: {controls: {_searchController: {_searchResults: results}}},
        hide: () => calls.push(['overview', 'hide']),
    };
    const context = vm.createContext({global: shellGlobal});
    const dependencies = {
        'gi://Clutter': {default: Clutter},
        'gi://GLib': {default: {}},
        'gi://Meta': {default: {}},
        'gi://Shell': {default: Shell},
        'resource:///org/gnome/shell/extensions/extension.js': {Extension: class {}},
        'resource:///org/gnome/shell/ui/main.js': {overview, modalCount: 0},
    };
    const filename = path.join(__dirname,
        '../.local/share/gnome-shell/extensions/super-o-search@codex.local/extension.js');
    const module = new vm.SourceTextModule(fs.readFileSync(filename, 'utf8'), {context});
    await module.link(specifier => {
        const exports = dependencies[specifier];
        assert.ok(exports, `Unexpected dependency: ${specifier}`);
        return new vm.SyntheticModule(Object.keys(exports), function () {
            for (const [name, value] of Object.entries(exports))
                this.setExport(name, value);
        }, {context});
    });
    await module.evaluate();
    const extension = new module.namespace.default();
    extension._previews = () => [];
    extension._mode = 'search';
    extension._enterHeld = false;
    return {extension, calls, first, selected, label, display, provider,
        results, entry, shellGlobal};
}

async function main() {
    // Desktop new-window actions apply even before the app is running (zter --standalone).
    {
        const {extension, first, calls} = await fixture();
        first.app.app_info.list_actions = () => ['new-window'];
        first.app.state = Shell.AppState.STOPPED;
        assert.equal(extension._activateSearchApp(), true);
        assert.deepEqual(calls, [
            ['first', 'animate'], ['first', 'new-window', -1], ['overview', 'hide'],
        ]);
    }
    // Running apps may support new windows without exposing a desktop action.
    {
        const {extension, first, calls} = await fixture();
        first.app.can_open_new_window = () => true;
        assert.equal(extension._activateSearchApp(), true);
        assert.deepEqual(calls, [
            ['first', 'animate'], ['first', 'new-window', -1], ['overview', 'hide'],
        ]);
    }
    // Unsupported and not-yet-running apps keep their normal launch behavior.
    for (const running of [true, false]) {
        const {extension, first, calls} = await fixture();
        first.app.state = running ? Shell.AppState.RUNNING : Shell.AppState.STOPPED;
        assert.equal(extension._activateSearchApp(), true);
        assert.deepEqual(calls, [['first', 'activate']]);
    }
    // A selected result, including its child label, takes precedence over the first app.
    for (const focus of ['selected', 'label']) {
        const f = await fixture();
        f.shellGlobal.stage.key_focus = f[focus];
        assert.equal(f.extension._activateSearchApp(), true);
        assert.deepEqual(f.calls, [
            ['selected', 'animate'], ['selected', 'new-window', -1], ['overview', 'hide'],
        ]);
    }
    // Search refreshes must never launch an app from the previous query.
    for (const change of [
        f => { f.entry.get_text = () => '   '; },
        f => { f.results._startingSearch = true; },
        f => { f.provider.searchInProgress = true; },
        f => { f.display.visible = false; },
        f => { f.results.terms = ['old']; },
        f => { f.display._terms = ['old']; },
        f => { f.first.app = null; }, // System actions are not applications.
    ]) {
        const f = await fixture();
        change(f);
        assert.equal(f.extension._activateSearchApp(), false);
        assert.deepEqual(f.calls, []);
    }
    // Holding Enter must not open several windows; release allows the next activation.
    {
        const {extension, first, calls} = await fixture();
        first.app.can_open_new_window = () => true;
        const event = type => ({
            type: () => type,
            get_key_symbol: () => Clutter.KEY_Return,
            get_state: () => 0,
        });
        assert.equal(extension._onCapturedEvent(event(Clutter.EventType.KEY_PRESS)), 'stop');
        assert.equal(extension._onCapturedEvent(event(Clutter.EventType.KEY_PRESS)), 'stop');
        assert.equal(calls.filter(call => call[1] === 'new-window').length, 1);
        extension._onCapturedEvent(event(Clutter.EventType.KEY_RELEASE));
        extension._onCapturedEvent(event(Clutter.EventType.KEY_PRESS));
        assert.equal(calls.filter(call => call[1] === 'new-window').length, 2);
    }
    console.log('GNOME Overview passed: new windows, desktop actions, fallback, selection, stale search, Enter repeat');
}

main().catch(error => {
    console.error(error);
    process.exitCode = 1;
});
