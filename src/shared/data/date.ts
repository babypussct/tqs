export type FirestoreDateLike = Date | string | { toDate: () => Date } | null | undefined;

export function toDate(value: FirestoreDateLike): Date | null {
  if (!value) return null;
  if (value instanceof Date) return Number.isNaN(value.getTime()) ? null : value;
  if (typeof value === 'object' && typeof value.toDate === 'function') {
    const date = value.toDate();
    return Number.isNaN(date.getTime()) ? null : date;
  }
  const date = new Date(value as string);
  return Number.isNaN(date.getTime()) ? null : date;
}

export function formatDate(value: FirestoreDateLike, options?: Intl.DateTimeFormatOptions): string {
  const date = toDate(value);
  return date ? date.toLocaleString('vi-VN', options) : '—';
}

export function formatDateOnly(value: FirestoreDateLike): string {
  return formatDate(value, { dateStyle: 'short' });
}

export function formatTime(value: FirestoreDateLike): string {
  return formatDate(value, { timeStyle: 'short' });
}
