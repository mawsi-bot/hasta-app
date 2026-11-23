# ADR-0008 — google-auth-library for Gmail linking (server)

Status: accepted (GitHub #6, HAS-300).

## Decision
`apps/server` depends on `google-auth-library` pinned at exactly `9.15.1` (no `^`), lockfile committed. It is used only inside `src/modules/identity/` (T37 gate) for two jobs: the server-side authorization-code exchange with PKCE, and id_token signature checks against Google's published certs (`verifySignedJwtWithCertsAsync`). We do not hand-roll JWT/RS256 verification.

## Guardrails
- The library checks signature, iss, aud and exp. `GoogleIdTokenVerifier` re-checks iss/aud/exp and adds nonce and `email_verified`. Gate T37 now also inspects cert-based verification calls, so removing any of the five checks fails the build.
- The id_token is never accepted from the client. `link:complete` takes only `{state, code}`, and unknown fields return 400.
- Network access goes through `GoogleOAuthPort` so that tests fake Google, never the verifier.

## Alternatives rejected
`jose` + manual JWKS (more code on a trust boundary); `passport-google-oauth20` (built for sign-in, which v1 forbids).
