import { looksLikeZawgyi } from '../../src/common/text/zawgyi';

// Zawgyi detect STUB (SPEC 1.0.1 §20 ruling): legacy input must never be stored as Zawgyi. Full
// detect → convert lands in Sprint 3; the stub rejects text with structural Zawgyi-only patterns.
describe('Zawgyi detect stub', () => {
  it.each([
    ['ေက်ာင္း', 'e-vowel before consonant + U+1039 used as asat'],
    ['ေမာင္ေမာင္', 'e-vowel at word start'],
    ['ကၽြန္ေတာ္', 'U+1039 not followed by a consonant'],
  ])('flags Zawgyi %s (%s)', (s) => expect(looksLikeZawgyi(s)).toBe(true));

  it.each(['ကျောင်း', 'မောင်မောင်', 'မင်္ဂလာပါ', 'ကျွန်တော်', 'Hasta 123', ''])('accepts Unicode / Latin %s', (s) =>
    expect(looksLikeZawgyi(s)).toBe(false));
});
