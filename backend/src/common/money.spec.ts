import {
  formatUzs,
  groupUzs,
  GROUP_SEPARATOR,
  patchBigIntJson,
  UZS_SUFFIX,
} from './money';

describe('money (int UZS)', () => {
  const sep = GROUP_SEPARATOR;

  it('groups thousands with the separator', () => {
    expect(groupUzs(1234567n)).toBe(`1${sep}234${sep}567`);
    expect(groupUzs(0n)).toBe('0');
    expect(groupUzs(999n)).toBe('999');
    expect(groupUzs(-12000n)).toBe(`-12${sep}000`);
  });

  it('formats with the UZS suffix', () => {
    expect(formatUzs(120000n)).toBe(`120${sep}000${sep}${UZS_SUFFIX}`);
    expect(formatUzs(120000n, false)).toBe(`120${sep}000`);
  });

  it('serializes BigInt as a string in JSON', () => {
    patchBigIntJson();
    const json = JSON.stringify({ total: 5000000000000n });
    expect(json).toBe('{"total":"5000000000000"}');
  });
});
