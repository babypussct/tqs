export interface Banner {
  image: string;
  title: string;
  subtitle: string;
  badge?: string;
  description?: string;
  buttonText?: string;
  link?: string;
}

export interface TrustBadge {
  icon: string;
  colorClass: string;
  title: string;
  desc: string;
}

export interface HomeSection {
  id: string;
  title: string;
  icon: string;
  iconColorClass: string;
  typeFilter: string;
}

export interface HeroEffects {
  particleEnabled: boolean;
  particleCount: number;           // 20–200
  particleColor: 'gold' | 'red' | 'white' | 'mixed';
  particleIntensity: number;       // 0.1–1.0 (opacity multiplier)
  particleDirection: 'up' | 'down' | 'random' | 'float'; // movement direction
  particleSizeMin: number;         // 0.5–5
  particleSizeMax: number;         // 1–8
  particleSpread: number;          // 0.1–2.0 horizontal drift
  // Animation layer: choose between particles, video, or none
  animationLayer: 'particles' | 'video' | 'none';
  videoUrl?: string;               // MP4/WebM URL for video overlay
  videoBlend: 'screen' | 'lighten' | 'overlay' | 'multiply' | 'normal';
  videoOpacity: number;            // 0.1–1.0
  videoLoop: boolean;
  overlayStrength: number;         // 0–100 (%)
  overlayStyle: 'dark' | 'gold' | 'red' | 'custom';
  overlayCustomColor?: string;     // hex color
  glowEnabled: boolean;
  glowColor: 'gold' | 'red' | 'white';
  animationPreset: 'cinematic' | 'epic' | 'subtle' | 'off';
  objectPosition: 'center' | 'top' | 'bottom' | 'left' | 'right';
}

export interface HomepageConfig {
  hero: {
    main: Banner;
    side1: Banner;
    side2: Banner;
    effects?: HeroEffects;
  };
  trustBadges: TrustBadge[];
  sections: HomeSection[];
}

export interface Product {
  id: string;
  name: string;
  price: number;
  originalPrice?: number;
  stock?: number;
  image: string;
  images?: string[]; // Additional image gallery
  badge?: string;
  isExpansion?: boolean;
  requiresBase?: boolean;
  size?: string;
  type: string;
  players?: string;
  playTime?: string;
  language?: 'vi' | 'zh';
  description?: string;
  specifications?: { name: string; value: string }[]; // Dynamic specifications
  addonIds?: string[]; // IDs of products that can be bought together
  soldCount?: number; // Number of items sold
  specs?: {
    cardCount?: number;
    material?: string;
    factions?: string[];
  };
  variants?: {
    boxType?: string[];
    language?: string[];
  };
  customVariants?: {
    name: string;
    options: { name: string; priceAdjustment?: number }[];
  }[];
  quickAddAccessories?: {
    name: string;
    price: number;
    description?: string;
  }[];
  isActive?: boolean;
  createdAt?: any;
}

export interface Category {
  id: string;
  name: string;
  slug: string;
}

export interface Review {
  id: string;
  productId: string;
  userId: string;
  userName: string;
  userPhoto?: string;
  rating: number;
  comment: string;
  createdAt: any;
  adminReply?: string;
  adminReplyAt?: any;
}

export interface CartItem {
  id: string; // Unique ID for the cart item (product.id + variants)
  product: Product;
  quantity: number;
  selectedBox?: string;
  selectedLang?: string;
  selectedVariants?: Record<string, string>; // Dynamic variants
  addSleeves?: boolean;
  quickAddAccessoryNames?: string[];
  price: number; // Calculated price including variants/sleeves
}

export interface DiscountCode {
  id: string;
  code: string;
  discountType: 'percentage' | 'fixed';
  discountValue: number;
  minOrderValue?: number;
  maxDiscount?: number;
  startDate: any;
  endDate: any;
  usageLimit?: number;
  usedCount: number;
  isActive: boolean;
  isFreeship?: boolean; // New field to allow discount codes to grant free shipping
  createdAt: any;
}

export interface ShippingConfig {
  isActive: boolean;
  defaultFee: number;
  freeshipThreshold: number | null;
  freeshipProductIds: string[];
}

export interface Order {
  id: string;
  userId: string;
  items: {
    productId: string;
    name: string;
    price: number;
    quantity: number;
    selectedBox: string | null;
    selectedLang: string | null;
    selectedVariants?: Record<string, string> | null;
    addSleeves: boolean;
    quickAddAccessoryNames?: string[] | null;
    image: string;
  }[];
  totalAmount: number;
  shippingFee?: number;
  discountCode?: string;
  discountAmount?: number;
  finalAmount?: number;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  paymentMethod?: 'cod' | 'vietqr';
  paymentStatus?: 'pending' | 'paid';
  trackingCode?: string;
  shippingInfo: {
    fullName: string;
    phone: string;
    address: string;
    notes: string;
  };
  createdAt: any;
  updatedAt: any;
}
