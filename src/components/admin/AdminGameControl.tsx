import { useEffect, useMemo, useState } from 'react';
import {
  collection,
  doc,
  deleteField,
  getDoc,
  onSnapshot,
  serverTimestamp,
  setDoc,
} from 'firebase/firestore';
import { Ban, CheckCircle2, Clock3, LockKeyhole, RefreshCw, Save, ShieldCheck, UserRound, Users } from 'lucide-react';
import { toast } from 'sonner';
import { db } from '../../firebase';
import { useAuth } from '../../contexts/AuthContext';
import type { GameAccess, GamePoolPolicy, GameAccessStatus } from '../../types';

type PackKind = 'generals' | 'cards';
type AccessDraft = { gameName: string };

const PACK_OPTIONS: Record<PackKind, Array<{ id: string; label: string }>> = {
  generals: [
    { id: 'hegemony_standard', label: 'Quốc Chiến Tiêu Chuẩn' },
    { id: 'hegemony_nos', label: 'Quốc Chiến Cổ Điển' },
    { id: 'formation', label: 'Trận Pháp' },
    { id: 'momentum', label: 'Biến Cục' },
    { id: 'transformation', label: 'Biến Hóa' },
    { id: 'power', label: 'Quyền Lực' },
    { id: 'lord_ex', label: 'Quân Chủ Mở Rộng' },
    { id: 'zqdl', label: 'Tử Khí Đông Lai' },
    { id: 'jyzs', label: 'Kim Ấn Tử Thụ' },
    { id: 'zfxp', label: 'Tử Phượng Hàm Bội' },
    { id: 'online_heg', label: 'Bản Quyền OL' },
    { id: 'mobile_heg', label: 'Bản Quyền Mobile' },
    { id: 'tenyear_heg', label: 'Quốc Chiến Thập Niên' },
    { id: 'overseas_heg', label: 'Quốc Chiến Quốc Tế' },
    { id: 'offline_heg', label: 'Quốc Chiến Ngoại Tuyến' },
  ],
  cards: [
    { id: 'hegemony_cards', label: 'Bài Tiêu Chuẩn' },
    { id: 'strategic_advantage', label: 'Ưu Thế Chiến Lược' },
    { id: 'nine_variations', label: 'Quốc Chiến Cửu Biến' },
    { id: 'lord_cards', label: 'Quân Lâm Thiên Hạ' },
    { id: 'm_lord_cards', label: 'Quân Lâm Thiên Hạ Mobile' },
  ],
};

const EMPTY_POLICY: GamePoolPolicy = {
  schemaVersion: 1,
  mode: 'new_heg_mode',
  revision: 0,
  disabledPacks: { generals: [], cards: [] },
  appliesTo: 'new_rooms',
  updatedAt: null,
  updatedBy: '',
};

function dateLabel(value: unknown): string {
  if (value && typeof value === 'object' && 'toDate' in value && typeof (value as { toDate?: unknown }).toDate === 'function') {
    return ((value as { toDate: () => Date }).toDate()).toLocaleString('vi-VN');
  }
  return 'Chưa có';
}

function defaultNativeName(access: GameAccess): string {
  const suffix = access.uid.replace(/[^A-Za-z0-9_-]/g, '').slice(0, 64);
  return `tqs_${suffix || 'player'}`.slice(0, 80);
}

function StatusBadge({ status }: { status: GameAccessStatus }) {
  const config: Record<GameAccessStatus, { label: string; className: string; icon: typeof Clock3 }> = {
    pending: { label: 'Chờ duyệt', className: 'text-amber-700 bg-amber-50 border-amber-200 dark:text-amber-300 dark:bg-amber-500/10 dark:border-amber-500/30', icon: Clock3 },
    approved: { label: 'Đã duyệt', className: 'text-emerald-700 bg-emerald-50 border-emerald-200 dark:text-emerald-300 dark:bg-emerald-500/10 dark:border-emerald-500/30', icon: CheckCircle2 },
    suspended: { label: 'Tạm dừng', className: 'text-rose-700 bg-rose-50 border-rose-200 dark:text-rose-300 dark:bg-rose-500/10 dark:border-rose-500/30', icon: Ban },
  };
  const item = config[status];
  const Icon = item.icon;
  return <span className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-semibold ${item.className}`}><Icon className="h-3.5 w-3.5" />{item.label}</span>;
}

export default function AdminGameControl() {
  const { adminUser } = useAuth();
  const canAccess = !!adminUser?.isSuperAdmin || adminUser?.permissions.manageGameAccess === true;
  const canPool = !!adminUser?.isSuperAdmin || adminUser?.permissions.manageGamePool === true;
  const [accesses, setAccesses] = useState<GameAccess[]>([]);
  const [accessDrafts, setAccessDrafts] = useState<Record<string, AccessDraft>>({});
  const [accessLoading, setAccessLoading] = useState(canAccess);
  const [policy, setPolicy] = useState<GamePoolPolicy>(EMPTY_POLICY);
  const [policyLoading, setPolicyLoading] = useState(canPool);
  const [savingUid, setSavingUid] = useState<string | null>(null);
  const [savingPolicy, setSavingPolicy] = useState(false);
  const [customGenerals, setCustomGenerals] = useState('');
  const [customCards, setCustomCards] = useState('');
  const knownIds = useMemo(() => new Set([
    ...PACK_OPTIONS.generals.map((item) => item.id),
    ...PACK_OPTIONS.cards.map((item) => item.id),
  ]), []);

  useEffect(() => {
    if (!canAccess) {
      setAccessLoading(false);
      return undefined;
    }
    return onSnapshot(collection(db, 'gameAccess'), (snapshot) => {
      const rows = snapshot.docs.map((item) => ({ uid: item.id, ...item.data() } as GameAccess));
      rows.sort((a, b) => {
        const statusRank: Record<GameAccessStatus, number> = { pending: 0, approved: 1, suspended: 2 };
        return statusRank[a.status] - statusRank[b.status];
      });
      setAccesses(rows);
      setAccessDrafts((current) => {
        const next = { ...current };
        for (const access of rows) {
          next[access.uid] ??= {
            gameName: access.gameName || access.displayName || 'Chúa Công',
          };
        }
        return next;
      });
      setAccessLoading(false);
    }, (error) => {
      console.error('Unable to read game access:', error);
      toast.error('Không tải được danh sách duyệt người chơi game.');
      setAccessLoading(false);
    });
  }, [canAccess]);

  useEffect(() => {
    if (!canPool) {
      setPolicyLoading(false);
      return undefined;
    }
    let active = true;
    void getDoc(doc(db, 'gamePoolPolicies', 'new_heg_mode')).then((snapshot) => {
      if (!active) return;
      const data = snapshot.data() as Partial<GamePoolPolicy> | undefined;
      const loaded: GamePoolPolicy = {
        ...EMPTY_POLICY,
        ...data,
        disabledPacks: {
          generals: Array.isArray(data?.disabledPacks?.generals) ? data.disabledPacks.generals : [],
          cards: Array.isArray(data?.disabledPacks?.cards) ? data.disabledPacks.cards : [],
        },
      };
      setPolicy(loaded);
      setCustomGenerals(loaded.disabledPacks.generals.filter((id) => !knownIds.has(id)).join(', '));
      setCustomCards(loaded.disabledPacks.cards.filter((id) => !knownIds.has(id)).join(', '));
      setPolicyLoading(false);
    }).catch((error) => {
      console.error('Unable to read game pool policy:', error);
      toast.error('Không tải được chính sách bể tướng / bể bài.');
      setPolicyLoading(false);
    });
    return () => { active = false; };
  }, [canPool]);

  const updateAccess = async (access: GameAccess, status: GameAccessStatus) => {
    if (!adminUser || !canAccess) return;
    const draft = accessDrafts[access.uid];
    // Native identity is always derived from the Firebase UID. Legacy names
    // cannot be migrated or retained through the admin form.
    const nativeName = defaultNativeName(access);
    const gameName = draft?.gameName.trim() || access.gameName?.trim() || access.displayName?.trim() || 'Chúa Công';
    setSavingUid(access.uid);
    try {
      await setDoc(doc(db, 'gameAccess', access.uid), {
        uid: access.uid,
        status,
        gameName,
        nativeName,
        email: access.email || null,
        displayName: access.displayName || null,
        note: access.note || '',
        nativeAccountId: deleteField(),
        updatedBy: adminUser.id,
        updatedAt: serverTimestamp(),
      }, { merge: true });
      setAccessDrafts((current) => ({ ...current, [access.uid]: { gameName } }));
      toast.success(status === 'approved' ? 'Đã duyệt quyền vào game.' : status === 'suspended' ? 'Đã tạm dừng quyền vào game.' : 'Đã chuyển về chờ duyệt.');
    } catch (error) {
      console.error('Unable to update game access:', error);
      toast.error('Không thể cập nhật quyền game.');
    } finally {
      setSavingUid(null);
    }
  };

  const togglePack = (kind: PackKind, id: string) => {
    setPolicy((current) => {
      const selected = current.disabledPacks[kind];
      return {
        ...current,
        disabledPacks: {
          ...current.disabledPacks,
          [kind]: selected.includes(id) ? selected.filter((item) => item !== id) : [...selected, id],
        },
      };
    });
  };

  const savePolicy = async () => {
    if (!adminUser || !canPool) return;
    const parseCustom = (value: string) => value.split(',').map((item) => item.trim()).filter(Boolean);
    const custom = [...parseCustom(customGenerals), ...parseCustom(customCards)];
    if (custom.some((id) => !/^[A-Za-z0-9_\-\u4e00-\u9fff]{1,100}$/u.test(id))) {
      toast.error('Pack bổ sung có ID không hợp lệ. Dùng các ký tự chữ, số, gạch ngang hoặc gạch dưới.');
      return;
    }
    const next = {
      schemaVersion: 1 as const,
      mode: 'new_heg_mode' as const,
      revision: Math.max(0, Number(policy.revision) || 0) + 1,
      disabledPacks: {
        generals: [...new Set([
          ...policy.disabledPacks.generals.filter((id) => knownIds.has(id)),
          ...parseCustom(customGenerals),
        ])],
        cards: [...new Set([
          ...policy.disabledPacks.cards.filter((id) => knownIds.has(id)),
          ...parseCustom(customCards),
        ])],
      },
      appliesTo: 'new_rooms' as const,
      updatedBy: adminUser.id,
      updatedAt: serverTimestamp(),
      note: policy.note || '',
    };
    setSavingPolicy(true);
    try {
      await setDoc(doc(db, 'gamePoolPolicies', 'new_heg_mode'), next);
      setPolicy({ ...next, updatedAt: null });
      setCustomGenerals(next.disabledPacks.generals.filter((id) => !knownIds.has(id)).join(', '));
      setCustomCards(next.disabledPacks.cards.filter((id) => !knownIds.has(id)).join(', '));
      toast.success(`Đã lưu chính sách bể, revision ${next.revision}.`);
    } catch (error) {
      console.error('Unable to save game pool policy:', error);
      toast.error('Không thể lưu chính sách bể.');
    } finally {
      setSavingPolicy(false);
    }
  };

  if (!canAccess && !canPool) {
    return <p className="rounded-xl border border-rose-200 bg-rose-50 p-4 text-sm text-rose-700 dark:border-rose-500/30 dark:bg-rose-500/10 dark:text-rose-300">Bạn chưa được cấp quyền quản lý game.</p>;
  }

  return (
    <div className="space-y-8">
      {canAccess && (
        <section className="space-y-5">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <h2 className="flex items-center gap-2 text-xl font-bold text-slate-900 dark:text-white"><Users className="h-6 w-6 text-indigo-500" /> Cấp quyền người chơi Tam Quốc Sát — Quốc Chiến</h2>
              <p className="mt-1 text-sm text-slate-500 dark:text-zinc-400">Mỗi tài khoản Firebase phải được duyệt trước khi API phát vé vào FreeKill. Tạm dừng sẽ chặn cả đăng nhập và reconnect mới.</p>
            </div>
            <span className="inline-flex items-center gap-2 text-xs font-semibold text-slate-500 dark:text-zinc-400"><ShieldCheck className="h-4 w-4 text-emerald-500" /> Không lưu mật khẩu native</span>
          </div>

          {accessLoading ? <Loading /> : accesses.length === 0 ? (
            <EmptyState text="Chưa có yêu cầu nào. Người dùng sẽ xuất hiện ở đây sau lần đầu chọn đăng nhập game." />
          ) : (
            <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm dark:border-zinc-800 dark:bg-zinc-900">
              <div className="overflow-x-auto">
                <table className="w-full min-w-[860px] text-left text-sm">
                  <thead className="border-b border-slate-200 bg-slate-50 text-xs uppercase tracking-wide text-slate-500 dark:border-zinc-800 dark:bg-zinc-950/50 dark:text-zinc-400">
                    <tr><th className="px-5 py-4">Người dùng</th><th className="px-5 py-4">Tên game</th><th className="px-5 py-4">Danh tính mới</th><th className="px-5 py-4">Trạng thái</th><th className="px-5 py-4 text-right">Thao tác</th></tr>
                  </thead>
                  <tbody className="divide-y divide-slate-200 dark:divide-zinc-800">
                    {accesses.map((access) => {
                      const draft = accessDrafts[access.uid] || {
                        gameName: access.gameName || access.displayName || 'Chúa Công',
                      };
                      return (
                      <tr key={access.uid} className="align-top hover:bg-slate-50/70 dark:hover:bg-zinc-800/30">
                        <td className="px-5 py-4"><div className="flex items-center gap-3"><div className="flex h-9 w-9 items-center justify-center rounded-full bg-indigo-100 text-indigo-600 dark:bg-indigo-500/15 dark:text-indigo-300"><UserRound className="h-4 w-4" /></div><div><div className="font-semibold text-slate-900 dark:text-white">{access.displayName || access.email || access.uid}</div><div className="text-xs text-slate-500 dark:text-zinc-500">{access.email || access.uid}</div></div></div></td>
                        <td className="px-5 py-4"><label className="block text-[10px] font-semibold uppercase tracking-wide text-slate-400">Tên hiển thị<input value={draft.gameName} onChange={(event) => setAccessDrafts((current) => ({ ...current, [access.uid]: { ...draft, gameName: event.target.value.slice(0, 80) } }))} maxLength={80} className="mt-1 w-full min-w-44 rounded-md border border-slate-200 bg-white px-2 py-1.5 text-sm font-medium normal-case tracking-normal text-slate-800 outline-none focus:border-indigo-500 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-200" /></label><div className="mt-1 text-xs text-slate-500 dark:text-zinc-500">Cập nhật: {dateLabel(access.updatedAt)}</div></td>
                        <td className="px-5 py-4"><div className="block text-[10px] font-semibold uppercase tracking-wide text-slate-400">Danh tính native mới</div><code className="mt-1 block min-w-44 rounded-md border border-slate-200 bg-slate-50 px-2 py-1.5 text-xs text-slate-700 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-300">{defaultNativeName(access)}</code><div className="mt-1 text-xs text-slate-500 dark:text-zinc-500">Không map hoặc giữ nick native cũ</div></td>
                        <td className="px-5 py-4"><StatusBadge status={access.status} /></td>
                        <td className="px-5 py-4 text-right"><div className="flex justify-end gap-2">{access.status !== 'approved' && <button className="inline-flex items-center gap-1.5 rounded-lg bg-emerald-600 px-3 py-2 text-xs font-semibold text-white hover:bg-emerald-700 disabled:opacity-50" disabled={savingUid === access.uid} onClick={() => void updateAccess(access, 'approved')}><CheckCircle2 className="h-3.5 w-3.5" /> Duyệt</button>}{access.status === 'approved' && <button className="inline-flex items-center gap-1.5 rounded-lg border border-rose-200 bg-rose-50 px-3 py-2 text-xs font-semibold text-rose-700 hover:bg-rose-100 disabled:opacity-50 dark:border-rose-500/30 dark:bg-rose-500/10 dark:text-rose-300" disabled={savingUid === access.uid} onClick={() => void updateAccess(access, 'suspended')}><Ban className="h-3.5 w-3.5" /> Tạm dừng</button>}{access.status === 'suspended' && <button className="inline-flex items-center gap-1.5 rounded-lg border border-indigo-200 bg-indigo-50 px-3 py-2 text-xs font-semibold text-indigo-700 hover:bg-indigo-100 disabled:opacity-50 dark:border-indigo-500/30 dark:bg-indigo-500/10 dark:text-indigo-300" disabled={savingUid === access.uid} onClick={() => void updateAccess(access, 'approved')}><RefreshCw className="h-3.5 w-3.5" /> Mở lại</button>}</div></td>
                      </tr>
                      );
                    })}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </section>
      )}

      {canPool && (
        <section className="space-y-5">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div><h2 className="flex items-center gap-2 text-xl font-bold text-slate-900 dark:text-white"><LockKeyhole className="h-6 w-6 text-amber-500" /> Bể tướng &amp; bể bài Quốc Chiến</h2><p className="mt-1 text-sm text-slate-500 dark:text-zinc-400">Khóa theo package cho tất cả phòng Quốc Chiến tạo mới. Phòng đang tồn tại giữ snapshot policy cũ.</p></div>
            <span className="rounded-full border border-indigo-200 bg-indigo-50 px-3 py-1 text-xs font-semibold text-indigo-700 dark:border-indigo-500/30 dark:bg-indigo-500/10 dark:text-indigo-300">Revision {policy.revision}</span>
          </div>
          {policyLoading ? <Loading /> : <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-zinc-800 dark:bg-zinc-900">
            <div className="grid gap-6 lg:grid-cols-2">
              {(['generals', 'cards'] as PackKind[]).map((kind) => (
                <fieldset key={kind} className="space-y-3"><legend className="mb-1 flex items-center gap-2 text-sm font-bold uppercase tracking-wide text-slate-700 dark:text-zinc-200">{kind === 'generals' ? 'Pack tướng' : 'Pack bài'}<span className="text-xs font-normal text-slate-400">({policy.disabledPacks[kind].length} đang khóa)</span></legend><div className="grid gap-2 sm:grid-cols-2">{PACK_OPTIONS[kind].map((item) => { const checked = policy.disabledPacks[kind].includes(item.id); return <label key={item.id} className={`flex cursor-pointer items-center justify-between gap-3 rounded-lg border px-3 py-2 text-sm transition-colors ${checked ? 'border-amber-300 bg-amber-50 text-amber-900 dark:border-amber-500/40 dark:bg-amber-500/10 dark:text-amber-200' : 'border-slate-200 text-slate-600 dark:border-zinc-800 dark:text-zinc-400'}`}><span>{item.label}<code className="mt-0.5 block text-[10px] opacity-60">{item.id}</code></span><input type="checkbox" checked={checked} onChange={() => togglePack(kind, item.id)} className="h-4 w-4 accent-amber-600" /></label>; })}</div><input value={kind === 'generals' ? customGenerals : customCards} onChange={(event) => kind === 'generals' ? setCustomGenerals(event.target.value) : setCustomCards(event.target.value)} placeholder="Pack ID bổ sung, ngăn cách bằng dấu phẩy" className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs text-slate-900 outline-none focus:border-indigo-500 dark:border-zinc-700 dark:bg-zinc-950 dark:text-white" /></fieldset>
              ))}
            </div>
            <div className="mt-6 flex flex-col gap-3 border-t border-slate-100 pt-5 dark:border-zinc-800 sm:flex-row sm:items-end"><label className="flex-1 text-sm font-medium text-slate-700 dark:text-zinc-300">Ghi chú revision<input value={policy.note || ''} onChange={(event) => setPolicy((current) => ({ ...current, note: event.target.value.slice(0, 500) }))} maxLength={500} className="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 outline-none focus:border-indigo-500 dark:border-zinc-700 dark:bg-zinc-950 dark:text-white" /></label><button onClick={() => void savePolicy()} disabled={savingPolicy} className="inline-flex items-center justify-center gap-2 rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-indigo-700 disabled:opacity-50"><Save className="h-4 w-4" />{savingPolicy ? 'Đang lưu…' : 'Lưu policy mới'}</button></div>
            <p className="mt-4 rounded-lg bg-slate-50 p-3 text-xs leading-5 text-slate-600 dark:bg-zinc-950/60 dark:text-zinc-400">Admin lock được thêm vào request tạo phòng và native template có lớp khóa bổ sung. Khi đổi policy trên production, cần đồng bộ danh sách forced pack vào cấu hình native và reload server theo runbook.</p>
          </div>}
        </section>
      )}
    </div>
  );
}

function Loading() {
  return <div className="flex min-h-24 items-center justify-center rounded-xl border border-slate-200 bg-white dark:border-zinc-800 dark:bg-zinc-900"><div className="h-5 w-5 animate-spin rounded-full border-2 border-indigo-600 border-t-transparent" /></div>;
}

function EmptyState({ text }: { text: string }) {
  return <div className="flex items-center gap-3 rounded-xl border border-dashed border-slate-300 bg-slate-50 p-5 text-sm text-slate-600 dark:border-zinc-700 dark:bg-zinc-900/50 dark:text-zinc-400"><Clock3 className="h-4 w-4" />{text}</div>;
}
