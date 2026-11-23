/**
 * Field-level Last-Writer-Wins merge on Hybrid Logical Clocks (SPEC §11.3).
 * HLC wire format: decimal string of a 64-bit value = (physical_ms << 16) | logical_counter.
 * Pure and deterministic — unit tested (groundwork for T18).
 */
export type FieldClocks = Record<string, string>;

export interface MergeResult<F extends string> {
  applied: F[];
  ignored: F[];
  clocks: FieldClocks;
  maxHlc: bigint;
}

export function parseHlc(v: string): bigint {
  if (!/^\d{1,20}$/.test(v)) throw new Error('invalid_hlc');
  const n = BigInt(v);
  if (n >= 1n << 64n) throw new Error('invalid_hlc');
  return n;
}

export function mergeFields<F extends string>(fields: readonly F[], incomingHlc: bigint, current: FieldClocks): MergeResult<F> {
  const applied: F[] = [];
  const ignored: F[] = [];
  const clocks: FieldClocks = { ...current };
  let maxHlc = 0n;
  for (const c of Object.values(current)) {
    const n = BigInt(c);
    if (n > maxHlc) maxHlc = n;
  }
  for (const f of fields) {
    const prev = current[f] !== undefined ? BigInt(current[f]!) : -1n;
    if (incomingHlc > prev) {
      applied.push(f);
      clocks[f] = incomingHlc.toString();
      if (incomingHlc > maxHlc) maxHlc = incomingHlc;
    } else {
      ignored.push(f);
    }
  }
  return { applied, ignored, clocks, maxHlc };
}
