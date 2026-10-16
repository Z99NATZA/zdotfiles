'use strict';

const vscode = require('vscode');
const { DEFAULT_STEP, resizeFocusedGroup } = require('./resize-layout');

async function resizeFocusedPane(amount) {
  const tabGroups = vscode.window.tabGroups.all;
  const activeGroup = vscode.window.tabGroups.activeTabGroup;
  let activeIndex = tabGroups.indexOf(activeGroup);

  if (activeIndex < 0 && Number.isInteger(activeGroup.viewColumn)) {
    activeIndex = activeGroup.viewColumn - 1;
  }
  if (activeIndex < 0 || tabGroups.length < 2) {
    return;
  }

  const layout = await vscode.commands.executeCommand('vscode.getEditorLayout');
  if (!resizeFocusedGroup(layout, activeIndex, amount)) {
    return;
  }

  await vscode.commands.executeCommand('vscode.setEditorLayout', layout);
}

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand(
      'znnn.focusedPane.expand',
      () => resizeFocusedPane(DEFAULT_STEP),
    ),
    vscode.commands.registerCommand(
      'znnn.focusedPane.shrink',
      () => resizeFocusedPane(-DEFAULT_STEP),
    ),
  );
}

function deactivate() {}

module.exports = { activate, deactivate };
