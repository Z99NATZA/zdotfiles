'use strict';

const HORIZONTAL = 0;
const DEFAULT_STEP = 60;
const DEFAULT_MIN_SIZE = 120;

function leafCount(node) {
  if (!Array.isArray(node.groups)) {
    return 1;
  }

  return node.groups.reduce((total, child) => total + leafCount(child), 0);
}

function findResizePair(groups, orientation, activeLeafIndex, firstLeafIndex = 0) {
  let leafIndex = firstLeafIndex;

  for (let index = 0; index < groups.length; index += 1) {
    const child = groups[index];
    const childLeafCount = leafCount(child);
    const containsActive = activeLeafIndex >= leafIndex
      && activeLeafIndex < leafIndex + childLeafCount;

    if (containsActive) {
      if (Array.isArray(child.groups)) {
        const nestedPair = findResizePair(
          child.groups,
          orientation === HORIZONTAL ? 1 : HORIZONTAL,
          activeLeafIndex,
          leafIndex,
        );
        if (nestedPair) {
          return nestedPair;
        }
      }

      if (orientation === HORIZONTAL && groups.length > 1) {
        const neighborIndex = index < groups.length - 1 ? index + 1 : index - 1;
        return { groups, activeIndex: index, neighborIndex };
      }

      return null;
    }

    leafIndex += childLeafCount;
  }

  return null;
}

function resizeFocusedGroup(
  layout,
  activeLeafIndex,
  amount,
  minimumSize = DEFAULT_MIN_SIZE,
) {
  if (!layout || !Array.isArray(layout.groups) || layout.groups.length < 2) {
    return false;
  }

  const pair = findResizePair(
    layout.groups,
    layout.orientation === 1 ? 1 : HORIZONTAL,
    activeLeafIndex,
  );
  if (!pair) {
    return false;
  }

  const active = pair.groups[pair.activeIndex];
  const neighbor = pair.groups[pair.neighborIndex];
  const activeSize = Number(active.size);
  const neighborSize = Number(neighbor.size);
  if (!Number.isFinite(activeSize) || !Number.isFinite(neighborSize)) {
    return false;
  }

  const totalSize = activeSize + neighborSize;
  const effectiveMinimum = Math.min(minimumSize, Math.max(1, totalSize / 2));
  const requestedSize = activeSize + amount;
  const nextActiveSize = Math.max(
    effectiveMinimum,
    Math.min(totalSize - effectiveMinimum, requestedSize),
  );
  const appliedAmount = nextActiveSize - activeSize;
  if (Math.abs(appliedAmount) < 0.5) {
    return false;
  }

  active.size = nextActiveSize;
  neighbor.size = neighborSize - appliedAmount;
  return true;
}

module.exports = {
  DEFAULT_STEP,
  resizeFocusedGroup,
};
