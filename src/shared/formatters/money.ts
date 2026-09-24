export const VND_FORMATTER = new Intl.NumberFormat('vi-VN', {
  style: 'currency',
  currency: 'VND',
});

export function formatVND(value: number | null | undefined): string {
  return VND_FORMATTER.format(Math.max(0, Number(value) || 0));
}

export function formatVNDCompact(value: number | null | undefined): string {
  return `${Math.max(0, Number(value) || 0).toLocaleString('vi-VN')}đ`;
}
