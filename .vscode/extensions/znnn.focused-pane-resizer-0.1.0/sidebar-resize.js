'use strict';

const FOCUS_SETTLE_DELAY_MS = 0;

function wait(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function createSidebarResizer(executeCommand, pause = wait) {
  let busy = false;

  return async function resizeSidebar(resizeCommand, options = {}) {
    if (busy) {
      return false;
    }

    busy = true;
    try {
      const restoreCommand = typeof options.restoreCommand === 'string'
        ? options.restoreCommand
        : null;

      await executeCommand('workbench.action.focusSideBar');
      await pause(FOCUS_SETTLE_DELAY_MS);
      await executeCommand(resizeCommand);

      if (restoreCommand) {
        await executeCommand(restoreCommand);
      }

      return true;
    } finally {
      busy = false;
    }
  };
}

module.exports = {
  FOCUS_SETTLE_DELAY_MS,
  createSidebarResizer,
};
