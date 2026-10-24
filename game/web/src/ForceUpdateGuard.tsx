import { useUpdateStore, type UpdateCoordinator } from './system/updates';
import { BUILD, buildLabel } from './system/buildInfo';
import SystemDialog from './SystemDialog';
export default function ForceUpdateGuard({ playing, updates }: { playing: boolean; updates: UpdateCoordinator }) {
  const state = useUpdateStore();
  if (!state.pending) return null;
  if (playing) return <div className="tqs-update-notice" role="status">● Có bản mới · Cập nhật sau khi kết thúc ván</div>;
  return <SystemDialog title="Cần cập nhật chiến trường" forced>
    <p>{state.reason}</p>
    <p>Bản đang lưu: <strong>{buildLabel(BUILD)}</strong></p>
    <p>Bản mới nhất: <strong>{state.latest ? buildLabel(state.latest) : 'Gói dữ liệu mới'}</strong></p>
    {state.error && <p role="alert">{state.error}</p>}
    <button type="button" className="button primary" disabled={state.applying} onClick={() => { void updates.apply(); }}>{state.applying ? 'Đang cập nhật…' : 'Cập Nhật Ngay'}</button>
  </SystemDialog>;
}
