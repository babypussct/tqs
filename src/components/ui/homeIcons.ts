import type { LucideIcon } from 'lucide-react';
import {
  Award,
  BookOpen,
  Box,
  CheckCircle,
  Flame,
  Gamepad2,
  Gift,
  Heart,
  PackageOpen,
  Shield,
  ShieldCheck,
  Sparkles,
  Star,
  Truck,
  Users,
  Zap,
} from 'lucide-react';

/**
 * Homepage icons are configured as strings in Firestore. Keep the dynamic
 * lookup bounded so the storefront does not import every Lucide icon into the
 * initial bundle just because an administrator can choose an icon by name.
 */
const HOME_ICON_MAP: Record<string, LucideIcon> = {
  Award,
  BookOpen,
  Box,
  CheckCircle,
  Flame,
  Gamepad2,
  Gift,
  Heart,
  PackageOpen,
  Shield,
  ShieldCheck,
  Sparkles,
  Star,
  Truck,
  Users,
  Zap,
};

export function resolveHomeIcon(name: unknown, fallback: LucideIcon = Star): LucideIcon {
  return typeof name === 'string' && HOME_ICON_MAP[name] ? HOME_ICON_MAP[name] : fallback;
}
