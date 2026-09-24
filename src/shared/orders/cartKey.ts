export function buildCartItemId(input: {
  productId: string;
  selectedBox?: string;
  selectedLang?: string;
  selectedVariants?: Record<string, string>;
  addSleeves?: boolean;
  quickAddAccessoryNames?: string[];
}): string {
  const variants = Object.entries(input.selectedVariants || {})
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([name, value]) => `${name}=${value}`)
    .join('&');
  const quickAdds = [...(input.quickAddAccessoryNames || [])].sort().join('|');
  return [
    input.productId,
    input.selectedBox || '',
    input.selectedLang || '',
    variants,
    input.addSleeves ? 'sleeves' : '',
    quickAdds,
  ].map((part) => encodeURIComponent(part)).join('::');
}
