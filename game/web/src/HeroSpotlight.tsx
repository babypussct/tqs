import { useState } from 'react';

export interface HeroInfo {
  id: string;
  name: string;
  badgeTitle: string;
  img: string;
  quote: string;
}

export const HEROES: HeroInfo[] = [
  {
    id: 'zhaoyun',
    name: 'Thần · Triệu Vân',
    badgeTitle: 'LONG ĐẢM',
    img: '/photo-assets/generals/godzhaoyun.webp',
    quote: '"Bạch mã ngân thương, một mình phá vây muôn trùng quân giặc!"',
  },
  {
    id: 'lvbu',
    name: 'Thần · Lã Bố',
    badgeTitle: 'VÔ SONG',
    img: '/photo-assets/generals/godlvbu.webp',
    quote: '"Chiến thần giáng thế, ai dám cùng ta tranh phong!"',
  },
  {
    id: 'zhouyu',
    name: 'Thần · Chu Du',
    badgeTitle: 'XÍCH BÍCH',
    img: '/photo-assets/generals/godzhouyu.webp',
    quote: '"Binh quỷ quạt lông khăn lụa, cười đùa tro bay khói tan!"',
  },
  {
    id: 'zhugeliang',
    name: 'Thần · Gia Cát Lượng',
    badgeTitle: 'NGỌA LONG',
    img: '/photo-assets/generals/godzhugeliang.webp',
    quote: '"Mượn gió đông Xích Bích, liệu việc như thần định càn khôn!"',
  },
];

interface HeroSpotlightProps {
  compact?: boolean;
}

export default function HeroSpotlight({ compact }: HeroSpotlightProps) {
  const [index, setIndex] = useState(0);
  const hero = HEROES[index];

  const nextHero = () => {
    setIndex((prev) => (prev + 1) % HEROES.length);
  };

  return (
    <div className={`sg-hero-card-container ${compact ? 'compact' : ''}`}>
      <div className="sg-hero-frame">
        <div className="sg-hero-faction-badge">THẦN</div>
        <div className="sg-hero-name-ribbon">
          <span className="sg-hero-title-tag">{hero.badgeTitle}</span>
        </div>
        <img src={hero.img} alt={hero.name} className="sg-hero-img" loading="eager" />
      </div>

      <div className="sg-hero-name-vn">{hero.name}</div>
      <div className="sg-hero-quote-box">{hero.quote}</div>

      <button type="button" className="sg-hero-switch-btn" onClick={nextHero}>
        <span>Đổi Võ Tướng</span>
      </button>
    </div>
  );
}
