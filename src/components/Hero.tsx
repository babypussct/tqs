import { useEffect, useRef } from 'react';
import { ArrowRight, ChevronDown } from 'lucide-react';
import { HomepageConfig } from '../types';
import { useNavigate } from 'react-router-dom';

interface HeroProps {
  data: HomepageConfig['hero'];
}

interface Particle {
  x: number;
  y: number;
  size: number;
  speedX: number;
  speedY: number;
  opacity: number;
  color: string;
}

export default function Hero({ data }: HeroProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const particlesRef = useRef<Particle[]>([]);
  const animFrameRef = useRef<number>(0);
  const navigate = useNavigate();

  // Particle system
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const resize = () => {
      canvas.width = canvas.offsetWidth;
      canvas.height = canvas.offsetHeight;
    };
    resize();
    window.addEventListener('resize', resize);

    const COLORS = [
      'rgba(255, 215, 0, 0.6)',   // gold
      'rgba(255, 200, 50, 0.4)',  // light gold
      'rgba(255, 255, 255, 0.3)', // white
      'rgba(220, 60, 60, 0.4)',   // red ember
      'rgba(255, 180, 0, 0.3)',   // amber
    ];

    const createParticle = (): Particle => ({
      x: Math.random() * canvas.width,
      y: canvas.height + Math.random() * 100,
      size: Math.random() * 2.5 + 0.5,
      speedX: (Math.random() - 0.5) * 0.6,
      speedY: -(Math.random() * 0.8 + 0.3),
      opacity: Math.random() * 0.7 + 0.1,
      color: COLORS[Math.floor(Math.random() * COLORS.length)],
    });

    // Init 100 particles spread across screen
    particlesRef.current = Array.from({ length: 100 }, () => {
      const p = createParticle();
      p.y = Math.random() * canvas.height; // start already spread
      return p;
    });

    const animate = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      particlesRef.current.forEach((p, i) => {
        p.x += p.speedX;
        p.y += p.speedY;
        // Flicker opacity
        p.opacity += (Math.random() - 0.5) * 0.02;
        p.opacity = Math.max(0.05, Math.min(0.8, p.opacity));

        if (p.y < -10) {
          particlesRef.current[i] = createParticle();
        }

        ctx.beginPath();
        ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
        ctx.fillStyle = p.color;
        ctx.shadowBlur = p.size * 4;
        ctx.shadowColor = p.color;
        ctx.globalAlpha = p.opacity;
        ctx.fill();
        ctx.globalAlpha = 1;
        ctx.shadowBlur = 0;
      });
      animFrameRef.current = requestAnimationFrame(animate);
    };

    animate();

    return () => {
      window.removeEventListener('resize', resize);
      cancelAnimationFrame(animFrameRef.current);
    };
  }, []);

  return (
    <div className="relative w-full h-screen min-h-[600px] overflow-hidden">
      {/* Background Image */}
      {data.main.image && (
        <img
          src={data.main.image}
          alt={data.main.title}
          className="absolute inset-0 w-full h-full object-cover object-center"
          referrerPolicy="no-referrer"
        />
      )}

      {/* Gradient Overlays — multi-layer like Sanguosha */}
      <div className="absolute inset-0 bg-gradient-to-r from-black/80 via-black/40 to-black/20 pointer-events-none" />
      <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/20 to-black/40 pointer-events-none" />
      <div className="absolute inset-0 bg-black/25 pointer-events-none" />

      {/* Particle Canvas */}
      <canvas
        ref={canvasRef}
        className="absolute inset-0 w-full h-full pointer-events-none z-10"
      />

      {/* Main Content */}
      <div className="relative z-20 flex flex-col justify-center h-full max-w-7xl mx-auto px-6 sm:px-10 lg:px-16 pb-20">
        {/* Badge */}
        {data.main.badge && (
          <div
            className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full text-xs font-bold uppercase tracking-widest mb-6 w-fit"
            style={{
              background: 'rgba(180, 20, 20, 0.85)',
              border: '1px solid rgba(255, 80, 80, 0.5)',
              boxShadow: '0 0 16px rgba(220, 30, 30, 0.6), 0 0 40px rgba(220, 30, 30, 0.2)',
              color: '#fff',
              animation: 'pulseBadge 2.5s ease-in-out infinite',
            }}
          >
            <span
              className="w-1.5 h-1.5 rounded-full bg-red-300 inline-block"
              style={{ animation: 'pulseDot 1.2s ease-in-out infinite' }}
            />
            {data.main.badge}
          </div>
        )}

        {/* Title */}
        <div className="mb-6">
          <h1
            className="text-5xl sm:text-6xl lg:text-7xl xl:text-8xl font-black text-white leading-tight"
            style={{
              textShadow:
                '0 0 40px rgba(255, 180, 0, 0.5), 0 0 80px rgba(255, 120, 0, 0.3), 2px 2px 0px rgba(0,0,0,0.8)',
              letterSpacing: '-0.02em',
            }}
          >
            {data.main.title}
          </h1>
          {data.main.subtitle && (
            <p
              className="text-3xl sm:text-4xl lg:text-5xl font-black mt-2"
              style={{
                background: 'linear-gradient(135deg, #FFD700 0%, #FF6B35 50%, #E53333 100%)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text',
                textShadow: 'none',
                filter: 'drop-shadow(0 0 20px rgba(255, 150, 0, 0.6))',
              }}
            >
              {data.main.subtitle}
            </p>
          )}
        </div>

        {/* Description */}
        {data.main.description && (
          <p
            className="text-gray-200 mb-8 max-w-lg text-base sm:text-lg leading-relaxed"
            style={{ textShadow: '0 1px 4px rgba(0,0,0,0.8)' }}
          >
            {data.main.description}
          </p>
        )}

        {/* CTA Button */}
        {data.main.buttonText && (
          <button
            onClick={() => navigate('/shop')}
            className="group relative w-fit flex items-center gap-3 text-white font-bold text-base px-8 py-4 rounded-xl overflow-hidden transition-transform duration-300 hover:scale-105 active:scale-95"
            style={{
              background: 'linear-gradient(135deg, #CC0000 0%, #FF3333 50%, #CC2200 100%)',
              boxShadow: '0 0 20px rgba(200, 20, 20, 0.7), 0 0 60px rgba(200, 20, 20, 0.3), 0 4px 15px rgba(0,0,0,0.5)',
              border: '1px solid rgba(255, 100, 100, 0.4)',
            }}
          >
            {/* Shimmer */}
            <span
              className="absolute inset-0 opacity-0 group-hover:opacity-100 transition-opacity duration-500"
              style={{
                background:
                  'linear-gradient(105deg, transparent 30%, rgba(255,255,255,0.25) 50%, transparent 70%)',
                animation: 'shimmer 1.5s ease-in-out infinite',
              }}
            />
            <span className="relative z-10">{data.main.buttonText}</span>
            <ArrowRight className="relative z-10 h-5 w-5 transition-transform duration-300 group-hover:translate-x-1" />
          </button>
        )}

        {/* Stats / Trust quick chips */}
        <div className="flex flex-wrap items-center gap-4 mt-8">
          {[
            { label: 'Sản phẩm chính hãng', icon: '✦' },
            { label: 'Đóng gói chuẩn sưu tầm', icon: '✦' },
            { label: 'Hoàn tiền nếu móp hộp', icon: '✦' },
          ].map((item, i) => (
            <span
              key={i}
              className="flex items-center gap-1.5 text-xs text-gray-300"
              style={{ textShadow: '0 1px 4px rgba(0,0,0,0.8)' }}
            >
              <span className="text-amber-400 text-[10px]">{item.icon}</span>
              {item.label}
            </span>
          ))}
        </div>
      </div>

      {/* Floating Side Cards (góc phải) */}
      <div className="absolute right-6 lg:right-12 top-1/2 -translate-y-1/2 z-20 hidden lg:flex flex-col gap-4">
        {[data.side1, data.side2].map((side, i) => (
          <div
            key={i}
            className="relative w-52 rounded-xl overflow-hidden cursor-pointer group"
            style={{
              background: 'rgba(0,0,0,0.5)',
              border: '1px solid rgba(255, 200, 100, 0.2)',
              boxShadow: '0 8px 32px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,200,100,0.1)',
              backdropFilter: 'blur(8px)',
              transition: 'all 0.3s ease',
            }}
            onMouseEnter={(e) => {
              (e.currentTarget as HTMLDivElement).style.borderColor = 'rgba(255, 200, 100, 0.5)';
              (e.currentTarget as HTMLDivElement).style.boxShadow =
                '0 8px 40px rgba(0,0,0,0.7), 0 0 0 1px rgba(255,200,100,0.3), 0 0 20px rgba(255,180,0,0.2)';
              (e.currentTarget as HTMLDivElement).style.transform = 'scale(1.03) translateX(-4px)';
            }}
            onMouseLeave={(e) => {
              (e.currentTarget as HTMLDivElement).style.borderColor = 'rgba(255, 200, 100, 0.2)';
              (e.currentTarget as HTMLDivElement).style.boxShadow =
                '0 8px 32px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,200,100,0.1)';
              (e.currentTarget as HTMLDivElement).style.transform = '';
            }}
            onClick={() => navigate('/shop')}
          >
            {side.image && (
              <img
                src={side.image}
                alt={side.title}
                className="w-full h-28 object-cover transition-transform duration-500 group-hover:scale-110"
                referrerPolicy="no-referrer"
              />
            )}
            <div
              className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/30 to-transparent"
            />
            <div className="absolute bottom-0 left-0 right-0 p-3">
              <p
                className="text-white font-bold text-sm leading-tight"
                style={{ textShadow: '0 1px 4px rgba(0,0,0,0.9)' }}
              >
                {side.title}
              </p>
              <p className="text-amber-400 text-xs font-medium mt-0.5">{side.subtitle}</p>
            </div>
            {/* Gold line accent */}
            <div
              className="absolute top-0 left-0 right-0 h-0.5"
              style={{
                background: 'linear-gradient(90deg, transparent, rgba(255,200,50,0.8), transparent)',
              }}
            />
          </div>
        ))}
      </div>

      {/* Scroll Down Indicator */}
      <div
        className="absolute bottom-8 left-1/2 -translate-x-1/2 z-20 flex flex-col items-center gap-2 cursor-pointer"
        onClick={() => window.scrollTo({ top: window.innerHeight, behavior: 'smooth' })}
        style={{ animation: 'floatDown 2s ease-in-out infinite' }}
      >
        <span
          className="text-xs uppercase tracking-widest text-gray-300"
          style={{ textShadow: '0 1px 4px rgba(0,0,0,0.8)' }}
        >
          Khám phá thêm
        </span>
        <ChevronDown
          className="h-5 w-5 text-amber-400"
          style={{ filter: 'drop-shadow(0 0 6px rgba(255,180,0,0.8))' }}
        />
      </div>

      {/* Corner decorative lines (Sanguosha style) */}
      <div className="absolute top-0 left-0 w-24 h-24 pointer-events-none z-20 hidden lg:block">
        <div className="absolute top-20 left-6 w-16 h-[1px]" style={{ background: 'linear-gradient(90deg, rgba(255,200,50,0.6), transparent)' }} />
        <div className="absolute top-20 left-6 w-[1px] h-16" style={{ background: 'linear-gradient(180deg, rgba(255,200,50,0.6), transparent)' }} />
      </div>
      <div className="absolute top-0 right-0 w-24 h-24 pointer-events-none z-10 hidden lg:block">
        <div className="absolute top-20 right-6 w-16 h-[1px]" style={{ background: 'linear-gradient(270deg, rgba(255,200,50,0.6), transparent)' }} />
        <div className="absolute top-20 right-6 w-[1px] h-16" style={{ background: 'linear-gradient(180deg, rgba(255,200,50,0.6), transparent)' }} />
      </div>

      {/* CSS Animations */}
      <style>{`
        @keyframes pulseBadge {
          0%, 100% { box-shadow: 0 0 16px rgba(220,30,30,0.6), 0 0 40px rgba(220,30,30,0.2); }
          50% { box-shadow: 0 0 24px rgba(220,30,30,0.9), 0 0 60px rgba(220,30,30,0.4); }
        }
        @keyframes pulseDot {
          0%, 100% { opacity: 1; transform: scale(1); }
          50% { opacity: 0.5; transform: scale(0.6); }
        }
        @keyframes shimmer {
          0% { transform: translateX(-100%); }
          100% { transform: translateX(200%); }
        }
        @keyframes floatDown {
          0%, 100% { transform: translateX(-50%) translateY(0px); opacity: 0.7; }
          50% { transform: translateX(-50%) translateY(6px); opacity: 1; }
        }
      `}</style>
    </div>
  );
}
