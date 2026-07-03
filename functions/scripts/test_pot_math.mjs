import assert from 'node:assert/strict';

import {
  computeBasePotCents,
  computeDebts,
  computeTotalPotCents,
  findWinnerUids,
  splitCentsDeterministic,
  sumDebtCents,
} from '../lib/potMath.js';

const shares = splitCentsDeterministic(100, ['b', 'a', 'c']);
assert.equal(shares.get('a'), 34);
assert.equal(shares.get('b'), 33);
assert.equal(shares.get('c'), 33);

assert.equal(computeBasePotCents(1000, 5), 5000);
assert.equal(computeTotalPotCents(5000, 2000), 7000);

const winners = findWinnerUids(
  [
    { uid: 'u1', predictedHomeScore: 2, predictedAwayScore: 1 },
    { uid: 'u2', predictedHomeScore: 1, predictedAwayScore: 0 },
    { uid: 'u3', predictedHomeScore: 2, predictedAwayScore: 1 },
  ],
  2,
  1,
);
assert.deepEqual(winners, ['u1', 'u3']);

// 3 losers × 2 winners → 6 debt lines; total equals pot
const debts = computeDebts(700, ['l1', 'l2', 'l3'], ['w1', 'w2']);
assert.equal(debts.length, 6);
assert.equal(sumDebtCents(debts), 700);

// Single loser pays single winner the full pot
const oneToOne = computeDebts(5000, ['l1'], ['w1']);
assert.deepEqual(oneToOne, [{ fromUid: 'l1', toUid: 'w1', amountCents: 5000 }]);

// Two losers, one winner: each loser pays half (remainder to first sorted uid)
const twoLosersOneWinner = computeDebts(101, ['b', 'a'], ['w1']);
assert.equal(sumDebtCents(twoLosersOneWinner), 101);
assert.deepEqual(
  twoLosersOneWinner.sort((a, b) => a.fromUid.localeCompare(b.fromUid)),
  [
    { fromUid: 'a', toUid: 'w1', amountCents: 51 },
    { fromUid: 'b', toUid: 'w1', amountCents: 50 },
  ],
);

// One loser, two winners: loser split among winners
const oneLoserTwoWinners = computeDebts(100, ['l1'], ['w2', 'w1']);
assert.equal(sumDebtCents(oneLoserTwoWinners), 100);
assert.deepEqual(
  oneLoserTwoWinners.sort((a, b) => a.toUid.localeCompare(b.toUid)),
  [
    { fromUid: 'l1', toUid: 'w1', amountCents: 50 },
    { fromUid: 'l1', toUid: 'w2', amountCents: 50 },
  ],
);

// No winners → no debts (pot carries over server-side)
const noWinnersDebts = computeDebts(700, ['l1'], []);
assert.equal(noWinnersDebts.length, 0);

// Everyone won → no losers → no debts
const noLosersDebts = computeDebts(700, [], ['w1', 'w2']);
assert.equal(noLosersDebts.length, 0);

// Only exact-score predictions win
const partialWinners = findWinnerUids(
  [
    { uid: 'u1', predictedHomeScore: 2, predictedAwayScore: 1 },
    { uid: 'u2', predictedHomeScore: 2, predictedAwayScore: 0 },
  ],
  2,
  1,
);
assert.deepEqual(partialWinners, ['u1']);

console.log('potMath tests passed');
