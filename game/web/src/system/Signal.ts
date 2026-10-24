import type { ConnectionStatus } from '../engine/connection';
export interface SignalSample { online: boolean; rtt: number | null; failed: boolean }
export function signalView(sample: SignalSample, connection: ConnectionStatus, phase: string) {
  if (!sample.online || sample.failed) return { tone: 'offline', bars: 0, label: 'Mất kết nối' };
  if ((connection.kind === 'closed' && phase === 'room') ||
      (phase === 'playing' && connection.kind !== 'online' && connection.kind !== 'booting'))
    return { tone: 'weak', bars: 1, label: 'Đang khôi phục…' };
  if (connection.kind === 'authenticating') return { tone: 'fair', bars: 2, label: 'Đang kiểm tra lệnh bài…' };
  if (connection.kind === 'connecting') return { tone: 'fair', bars: 2, label: 'Đang kết nối…' };
  if (sample.rtt === null) return { tone: 'fair', bars: 0, label: 'Đang đo tín hiệu…' };
  if (sample.rtt < 100) return { tone: 'good', bars: 3, label: 'Ổn định' };
  if (sample.rtt <= 250) return { tone: 'fair', bars: 2, label: 'Khá' };
  return { tone: 'weak', bars: 1, label: 'Tín hiệu yếu' };
}
