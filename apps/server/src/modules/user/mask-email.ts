/** `heinhtet@gmail.com` → `h***@gmail.com` (SPEC §5.4). Full email is never returned by list APIs. */
export function maskEmail(email: string | null): string | null {
  if (!email) return null;
  const at = email.lastIndexOf('@');
  if (at < 1) return '***';
  return `${email[0]}***${email.slice(at)}`;
}
