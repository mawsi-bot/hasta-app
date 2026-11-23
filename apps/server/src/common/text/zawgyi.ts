/**
 * Zawgyi detect STUB (SKILL rule 5, SPEC 1.0.1 ruling). Flags structural patterns that cannot occur in valid
 * Unicode Burmese: U+1031 (e-vowel) typed before its consonant, and U+1039 (virama) not followed by a
 * consonant (Zawgyi uses it as asat). Low false-positive by design; Sprint 3 replaces it with the full
 * detect → convert pipeline. Callers REJECT flagged input so legacy text is never stored as Zawgyi.
 */
const ZAWGYI_ONLY = /(^|[\s\u104a\u104b])\u1031|\u1039(?![\u1000-\u1021])/u;

export const looksLikeZawgyi = (s: string): boolean => ZAWGYI_ONLY.test(s);
