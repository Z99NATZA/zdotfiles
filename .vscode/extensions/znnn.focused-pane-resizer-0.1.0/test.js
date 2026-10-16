'use strict';

const assert = require('node:assert/strict');
const { resizeFocusedGroup } = require('./resize-layout');
const {
  FOCUS_SETTLE_DELAY_MS,
  createSidebarResizer,
} = require('./sidebar-resize');

function horizontal(...sizes) {
  return { orientation: 0, groups: sizes.map((size) => ({ size })) };
}

{
  const layout = horizontal(500, 500);
  assert.equal(resizeFocusedGroup(layout, 0, 60), true);
  assert.deepEqual(layout.groups.map(({ size }) => size), [560, 440]);
}

{
  const layout = horizontal(500, 500);
  assert.equal(resizeFocusedGroup(layout, 1, 60), true);
  assert.deepEqual(layout.groups.map(({ size }) => size), [440, 560]);
}

{
  const layout = horizontal(400, 400, 400);
  assert.equal(resizeFocusedGroup(layout, 1, -60), true);
  assert.deepEqual(layout.groups.map(({ size }) => size), [400, 340, 460]);
}

{
  const layout = horizontal(400, 400, 400);
  assert.equal(resizeFocusedGroup(layout, 2, -60), true);
  assert.deepEqual(layout.groups.map(({ size }) => size), [400, 460, 340]);
}

{
  const layout = {
    orientation: 1,
    groups: [
      { size: 600, groups: [{ size: 500 }, { size: 500 }] },
      { size: 600, groups: [{ size: 500 }, { size: 500 }] },
    ],
  };
  assert.equal(resizeFocusedGroup(layout, 1, 60), true);
  assert.deepEqual(layout.groups[0].groups.map(({ size }) => size), [440, 560]);
  assert.equal(layout.groups[1].size, 600);
}

async function testSidebarResizer() {
  {
    const events = [];
    const resizeSidebar = createSidebarResizer(
      async (command) => events.push(['command', command]),
      async (milliseconds) => events.push(['pause', milliseconds]),
    );

    assert.equal(await resizeSidebar(
      'workbench.action.decreaseViewSize',
      { restoreCommand: 'workbench.action.focusActiveEditorGroup' },
    ), true);
    assert.deepEqual(events, [
      ['command', 'workbench.action.focusSideBar'],
      ['pause', FOCUS_SETTLE_DELAY_MS],
      ['command', 'workbench.action.decreaseViewSize'],
      ['command', 'workbench.action.focusActiveEditorGroup'],
    ]);
  }

  {
    let releaseFocus;
    const resizeSidebar = createSidebarResizer(
      (command) => {
        if (command === 'workbench.action.focusSideBar') {
          return new Promise((resolve) => {
            releaseFocus = resolve;
          });
        }
        return Promise.resolve();
      },
      async () => {},
    );

    const firstResize = resizeSidebar('workbench.action.decreaseViewSize');
    assert.equal(
      await resizeSidebar('workbench.action.decreaseViewSize'),
      false,
    );
    releaseFocus();
    assert.equal(await firstResize, true);
  }
}

testSidebarResizer()
  .then(() => console.log('focused-pane-resizer tests passed'))
  .catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
