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

const debts = computeDebts(700, ['l1', 'l2', 'l3'], ['w1', 'w2']);
assert.equal(debts.length, 6);
assert.equal(sumDebtCents(debts), 700);

const noWinnersDebts = computeDebts(700, ['l1'], []);
assert.equal(noWinnersDebts.length, 0);

console.log('potMath tests passed');
