export const FIRESTORE_PATHS = {
  settings: {
    homepage: ['settings', 'homepage'] as const,
    site: ['settings', 'siteConfig'] as const,
    navigation: ['settings', 'navigationConfig'] as const,
    footer: ['settings', 'footerConfig'] as const,
    payment: ['settings', 'paymentConfig'] as const,
  },
  systemSettings: {
    shipping: ['system_settings', 'shipping_config'] as const,
    tiers: ['system_settings', 'tiers_config'] as const,
  },
} as const;
