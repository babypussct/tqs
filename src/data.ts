import { Product } from './types';

export const MOCK_PRODUCTS: Product[] = [
  {
    id: 'tqs-base-2024',
    name: 'Tam Quốc Sát - Bản Tiêu Chuẩn 2024 (Tiếng Việt)',
    price: 350000,
    originalPrice: 400000,
    image: 'https://picsum.photos/seed/tqs-base/600/600',
    badge: 'Best Seller',
    isExpansion: false,
    size: '62x89mm',
    type: 'base',
    players: '2-10',
    playTime: '30-60 phút',
    language: 'vi',
    description: 'Phiên bản Tiêu Chuẩn 2024 mới nhất với artwork được làm lại tuyệt đẹp. Trải nghiệm những trận chiến cân não, đấu trí đỉnh cao thời Tam Quốc. Cam kết hàng chính hãng 100%, đền bù gấp 10 nếu phát hiện hàng giả.',
    specs: {
      cardCount: 160,
      material: 'Giấy Bluecore cao cấp, cán mờ chống nước nhẹ',
      factions: ['Ngụy', 'Thục', 'Ngô', 'Quần Hùng']
    },
    variants: {
      boxType: ['Hộp Giấy (Tiêu Chuẩn)', 'Hộp Sắt (Sưu Tầm +50k)'],
      language: ['Tiếng Việt', 'Tiếng Trung']
    }
  },
  {
    id: 'tqs-phls',
    name: 'Tam Quốc Sát - Phong Hỏa Lâm Sơn (Bản Mở Rộng)',
    price: 250000,
    image: 'https://picsum.photos/seed/tqs-phls/600/600',
    badge: 'New',
    isExpansion: true,
    requiresBase: true,
    size: '62x89mm',
    type: 'expansion',
    language: 'vi',
    description: 'Bản mở rộng bổ sung hàng loạt tướng mới và cơ chế chơi đột phá. Yêu cầu phải có Bản Tiêu Chuẩn để chơi chung.',
    specs: {
      cardCount: 52,
      material: 'Giấy Bluecore cao cấp',
      factions: ['Ngụy', 'Thục', 'Ngô', 'Quần Hùng', 'Thần']
    }
  },
  {
    id: 'tqs-quoc-chien',
    name: 'Tam Quốc Sát - Quốc Chiến (Bản Độc Lập)',
    price: 450000,
    image: 'https://picsum.photos/seed/tqs-quoc-chien/600/600',
    isExpansion: false,
    size: '62x89mm',
    type: 'base',
    players: '4-12',
    language: 'vi'
  },
  {
    id: 'tqs-base-zh',
    name: 'Tam Quốc Sát - Bản Tiêu Chuẩn (Tiếng Trung)',
    price: 280000,
    image: 'https://picsum.photos/seed/tqs-zh/600/600',
    isExpansion: false,
    size: '62x89mm',
    type: 'base',
    players: '2-10',
    language: 'zh'
  },
  {
    id: 'acc-sleeves-6289',
    name: 'Bọc Bài (Sleeves) Dày 62x89mm (Xấp 100 cái)',
    price: 25000,
    originalPrice: 35000,
    image: 'https://picsum.photos/seed/sleeves/600/600',
    badge: 'Must Have',
    isExpansion: false,
    type: 'accessory'
  },
  {
    id: 'combo-quan-hung',
    name: 'Combo Quần Hùng Tranh Bá (Cơ Bản + Phong Hỏa Lâm Sơn + 400 Sleeves)',
    price: 650000,
    originalPrice: 750000,
    image: 'https://picsum.photos/seed/combo1/600/600',
    badge: 'Tiết kiệm 100k',
    isExpansion: false,
    type: 'combo',
    language: 'vi'
  }
];
