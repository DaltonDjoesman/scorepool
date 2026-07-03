import assert from 'node:assert/strict';

import {
  canSoftExclude,
  isFutureMatch,
  isLockedInGroup,
  matchIncludedInFilter,
} from '../lib/groupMatchReconciliation.js';

const now = new Date('2026-06-15T12:00:00.000Z');
const futureMatch = {
  matchTimeUtc: '2026-06-20T18:00:00.000Z',
  status: 'scheduled',
  homeTeamId: 'BRA',
  awayTeamId: 'ARG',
  stage: 'group',
};

assert.equal(
  matchIncludedInFilter(futureMatch, { teamIds: ['BRA'], stages: [] }),
  true,
);
assert.equal(
  matchIncludedInFilter(futureMatch, { teamIds: [], stages: ['final'] }),
  false,
);
assert.equal(
  matchIncludedInFilter(futureMatch, { teamIds: [], stages: ['group'] }),
  true,
);

assert.equal(isFutureMatch(futureMatch, now), true);
assert.equal(isLockedInGroup(futureMatch, 15, now), false);
assert.equal(canSoftExclude(futureMatch, 15, now), true);

const lockedMatch = {
  matchTimeUtc: '2026-06-15T12:10:00.000Z',
  status: 'scheduled',
};
assert.equal(isLockedInGroup(lockedMatch, 15, now), true);
assert.equal(canSoftExclude(lockedMatch, 15, now), false);

const liveMatch = {
  matchTimeUtc: '2026-06-20T18:00:00.000Z',
  status: 'live',
};
assert.equal(canSoftExclude(liveMatch, 15, now), false);

console.log('groupMatchReconciliation tests passed');
