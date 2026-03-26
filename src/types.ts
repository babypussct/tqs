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

export interface HomepageConfig {
  hero: {
    main: Banner;
    side1: Banner;
    side2: Banner;
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
  createdAt: any;
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
  discountCode?: string;
  discountAmount?: number;
  finalAmount?: number;
  status: 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';
  shippingInfo: {
    fullName: string;
    phone: string;
    address: string;
    notes: string;
  };
  createdAt: any;
  updatedAt: any;
}
