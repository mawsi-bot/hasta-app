/**
 * Seeded QA accounts (SPEC §19). Only ever created when HASTA_ENV ∈ {dev,test,beta}.
 * Social graph / dating fixtures for these handles are added by the sprints that own those tables
 * (Sprint 2 friends, Sprint 4 groups/pages, Sprint 7 dating profiles).
 */
export type SeedHandle = 'tester.a' | 'tester.b' | 'tester.social' | 'tester.premium' | 'tester.minor' | 'tester.fresh';

export interface SeedAccount {
  handle: SeedHandle;
  purpose: string;
  displayName: string | null;
  /** birth date resolver so tester.minor stays < 18 forever */
  birthDate: (today: Date) => string | null;
  bio: string | null;
  linkedGoogle: boolean;
  premium: boolean;
}

const yearsAgo = (today: Date, years: number) => {
  const d = new Date(Date.UTC(today.getUTCFullYear() - years, today.getUTCMonth(), today.getUTCDate()));
  return d.toISOString().slice(0, 10);
};

export const SEED_ACCOUNTS: readonly SeedAccount[] = [
  { handle: 'tester.a', purpose: 'dating_match_pair', displayName: 'Tester A', birthDate: () => '1996-05-14', bio: 'QA dating pair (A)', linkedGoogle: false, premium: false },
  { handle: 'tester.b', purpose: 'dating_match_pair', displayName: 'Tester B', birthDate: () => '1998-09-02', bio: 'QA dating pair (B)', linkedGoogle: false, premium: false },
  { handle: 'tester.social', purpose: 'feed_group_page', displayName: 'Tester Social', birthDate: () => '1993-01-20', bio: 'QA social flows', linkedGoogle: false, premium: false },
  { handle: 'tester.premium', purpose: 'entitlement_restore', displayName: 'Tester Premium', birthDate: () => '1990-11-11', bio: 'QA premium', linkedGoogle: true, premium: true },
  { handle: 'tester.minor', purpose: 'age_gate_18', displayName: 'Tester Minor', birthDate: (t) => yearsAgo(t, 16), bio: 'QA under-18', linkedGoogle: false, premium: false },
  { handle: 'tester.fresh', purpose: 'clean_guest', displayName: null, birthDate: () => null, bio: null, linkedGoogle: false, premium: false },
];

export const SEED_HANDLES = SEED_ACCOUNTS.map((s) => s.handle);
