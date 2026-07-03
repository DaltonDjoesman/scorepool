export function splitCentsDeterministic(
  totalCents: number,
  recipientUids: string[],
): Map<string, number> {
  if (recipientUids.length === 0) {
    return new Map();
  }

  const sorted = [...recipientUids].sort();
  const base = Math.floor(totalCents / sorted.length);
  const remainder = totalCents % sorted.length;
  const shares = new Map<string, number>();

  for (let i = 0; i < sorted.length; i += 1) {
    shares.set(sorted[i], base + (i < remainder ? 1 : 0));
  }

  return shares;
}

export function computeBasePotCents(
  entryFeeCents: number,
  inPotCount: number,
): number {
  return entryFeeCents * inPotCount;
}

export function computeTotalPotCents(
  basePotCents: number,
  accumulatedFromPreviousCents: number,
): number {
  return basePotCents + accumulatedFromPreviousCents;
}

export type PredictionScores = {
  uid: string;
  predictedHomeScore: number;
  predictedAwayScore: number;
};

export function findWinnerUids(
  predictions: PredictionScores[],
  homeScore: number,
  awayScore: number,
): string[] {
  return predictions
    .filter(
      (prediction) =>
        prediction.predictedHomeScore === homeScore &&
        prediction.predictedAwayScore === awayScore,
    )
    .map((prediction) => prediction.uid)
    .sort();
}

export type DebtLine = {
  fromUid: string;
  toUid: string;
  amountCents: number;
};

export function computeDebts(
  totalPotCents: number,
  loserUids: string[],
  winnerUids: string[],
): DebtLine[] {
  if (winnerUids.length === 0 || loserUids.length === 0 || totalPotCents <= 0) {
    return [];
  }

  const loserShares = splitCentsDeterministic(totalPotCents, loserUids);
  const debts: DebtLine[] = [];

  for (const loserUid of [...loserUids].sort()) {
    const loserTotal = loserShares.get(loserUid) ?? 0;
    if (loserTotal <= 0) continue;

    const perWinner = splitCentsDeterministic(loserTotal, winnerUids);
    for (const winnerUid of [...winnerUids].sort()) {
      const amountCents = perWinner.get(winnerUid) ?? 0;
      if (amountCents <= 0) continue;
      debts.push({ fromUid: loserUid, toUid: winnerUid, amountCents });
    }
  }

  return debts;
}

export function sumDebtCents(debts: DebtLine[]): number {
  return debts.reduce((sum, debt) => sum + debt.amountCents, 0);
}

export function debtItemId(fromUid: string, toUid: string): string {
  return `${fromUid}_${toUid}`;
}
