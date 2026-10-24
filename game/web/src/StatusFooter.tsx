import { useEffect, useRef, useState } from 'react';
import { useGameStore } from './store/gameStore';
import { BUILD, buildLabel } from './system/buildInfo';
import { fetchFresh, useUpdateStore, type UpdateCoordinator } from './system/updates';
import { signalView, type SignalSample } from './system/Signal';
import SystemDialog from './SystemDialog';

export default function StatusFooter({ gateway, updates, disconnect }: {
  gateway: string; updates: UpdateCoordinator; disconnect: () => void;
}) {
  const { phase, connection, manifest, progress } = useGameStore();
  const update = useUpdateStore();
  const [modal, setModal] = useState<'signal' | 'version' | null>(null);
  const [sample, setSample] = useState<SignalSample>({ online: navigator.onLine, rtt: null, failed: false });
  const [measuring, setMeasuring] = useState(false);
  const probe = useRef<() => void>(() => {});
  useEffect(() => {
    let active = true; let running = false;
    const measure = async () => {
      if (!active || running || document.visibilityState !== 'visible') return;
      if (!navigator.onLine) { setSample({ online: false, rtt: null, failed: false }); return; }
      running = true; setMeasuring(true);
      const start = performance.now();
      try {
        await fetchFresh(`${gateway}/healthz?t=${Date.now()}`);
        if (active) setSample({ online: navigator.onLine, rtt: Math.round(performance.now() - start), failed: false });
      } catch { if (active) setSample({ online: navigator.onLine, rtt: null, failed: true }); }
      finally { running = false; if (active) setMeasuring(false); }
    };
    probe.current = () => { void measure(); };
    const offline = () => setSample({ online: false, rtt: null, failed: false });
    const online = () => { setSample({ online: true, rtt: null, failed: false }); void measure(); };
    const visible = () => { if (document.visibilityState === 'visible') void measure(); };
    void measure();
    const timer = setInterval(() => { void measure(); }, 15000);
    window.addEventListener('online', online); window.addEventListener('offline', offline);
    document.addEventListener('visibilitychange', visible);
    return () => {
      active = false; clearInterval(timer); window.removeEventListener('online', online);
      window.removeEventListener('offline', offline); document.removeEventListener('visibilitychange', visible);
    };
  }, [gateway]);
  useEffect(() => { if (phase === 'playing') setModal(null); }, [phase]);
  const view = signalView(sample, connection, phase);
  return <>
    {phase !== 'playing' && <footer className="tqs-status-footer" aria-label="Trạng thái hệ thống">
      <button type="button" className={`tqs-signal ${view.tone}`} onClick={() => setModal('signal')} aria-label="Chi tiết kết nối">
        <svg width="19" height="19" viewBox="0 0 20 20" aria-hidden="true">
          {[6, 11, 16].map((h, i) => <rect key={h} x={1 + i * 6} y={19 - h} width="4" height={h} rx="1" fill="currentColor" opacity={i < view.bars ? 1 : .2} />)}
        </svg><span className="tqs-signal-dot" /><span>{sample.rtt !== null && `${sample.rtt}ms · `}{view.label}</span>
      </button>
      <button type="button" className="tqs-version" onClick={() => setModal('version')} aria-label="Thông tin phiên bản">
        {buildLabel(BUILD)}{update.pending && <span className="tqs-new-version"> ● Có bản mới</span>}
      </button>
    </footer>}
    {modal && <SystemDialog title={modal === 'signal' ? 'Chi tiết kết nối' : 'Thông tin Phiên bản & Đồng bộ Hệ thống'} close={() => setModal(null)}>
      {modal === 'signal' ? <>
        <dl className="tqs-system-details">
          <dt>Mạng thiết bị</dt><dd>{sample.online ? 'Trực tuyến' : 'Ngoại tuyến'}</dd>
          <dt>Độ trễ cổng doanh trại</dt><dd>{sample.rtt === null ? 'Chưa đo được' : `${sample.rtt} ms · ${view.label}`}</dd>
          <dt>Máy chủ Quốc Chiến</dt><dd>{connection.kind === 'online' ? 'Đã xác thực' : connection.kind === 'authenticating' ? 'Đang xác thực' : connection.kind === 'connecting' ? 'Đang ở cổng' : 'Chưa kết nối'}</dd>
          <dt>Dữ liệu chiến trường</dt><dd>{manifest ? `${manifest.fileCount} tệp đã xác minh` : progress || 'Đang chuẩn bị'}</dd>
          <dt>MD5</dt><dd>{manifest?.md5 ?? 'Chưa nạp'}</dd>
        </dl>
        <button className="button secondary" disabled={measuring || !sample.online} onClick={() => probe.current()}>{measuring ? 'Đang đo…' : 'Đo lại tín hiệu'}</button>
        {phase === 'lobby' && <button className="button ghost" onClick={() => { setModal(null); disconnect(); }}>Ngắt kết nối</button>}
      </> : <>
        <dl className="tqs-system-details">
          <dt>Phiên bản Client</dt><dd>v{BUILD.version}</dd><dt>Mã bản dựng</dt><dd>{BUILD.buildId}</dd>
          <dt>Ngày giờ bản dựng</dt><dd>{BUILD.builtAt ? new Date(BUILD.builtAt).toLocaleString('vi-VN') : 'Phát triển local'}</dd>
          <dt>Gói dữ liệu máy chủ</dt><dd>{manifest?.bundleHash ?? 'Chưa nạp'}</dd>
          <dt>Đồng bộ</dt><dd>{update.pending ? update.reason : update.checkedAt ? 'Đã kiểm tra phiên bản' : 'Chưa kiểm tra'}</dd>
        </dl>
        {update.error && <p role="alert">{update.error}</p>}
        <button className="button primary" disabled={phase === 'playing' || update.applying || update.checking} onClick={() => { void updates.apply(true); }}>Kiểm tra cập nhật & Xóa bộ nhớ đệm</button>
      </>}
    </SystemDialog>}
  </>;
}
