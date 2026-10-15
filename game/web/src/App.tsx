import { useEffect, useMemo, useState } from 'react';
import { GameAdapter } from './engine/gameAdapter';
import { useGameStore } from './store/gameStore';
import GameBoardScreen from './GameBoardScreen';
import SkillInvokePanel from './SkillInvokePanel';
import ChoicePanel from './ChoicePanel';
import CardSelectionPanel from './CardSelectionPanel';
import CardsAndChoicePanel from './CardsAndChoicePanel';
import GameResultPanel from './GameResultPanel';
import { emptyBoard } from './store/boardState';
import { GAMEPLAY_REQUESTS } from './store/gameplayState';
import RequestDeadline from './RequestDeadline';
import NativeDialogPanel from './NativeDialogPanel';
import BootScreen from './BootScreen';
import LoginScreen from './LoginScreen';
import LobbyScreen, { WaitingRoomScreen } from './LobbyScreen';
import InitialGeneralPanel from './InitialGeneralPanel';

export { default as LobbyScreen } from './LobbyScreen';
export { WaitingRoomScreen } from './LobbyScreen';

const gateway = (import.meta.env.VITE_GATEWAY_URL ?? '/gateway').replace(/\/$/, '');

export default function App() {
  const adapter = useMemo(() => new GameAdapter(gateway), []);
  const snapshot = useGameStore();
  const [busy, setBusy] = useState(false);
  const [networkOnline, setNetworkOnline] = useState(navigator.onLine);
  const [exitAction, setExitAction] = useState<'leave' | 'disconnect' | null>(null);
  useEffect(() => {
    const changed = () => setNetworkOnline(navigator.onLine);
    window.addEventListener('online', changed);
    window.addEventListener('offline', changed);
    return () => { window.removeEventListener('online', changed); window.removeEventListener('offline', changed); };
  }, []);
  const trusting = snapshot.players.find((player) => player.id === snapshot.ownId)?.netState === 'trust';

  useEffect(() => {
    const controller = new AbortController();
    void adapter.boot(controller.signal);
    return () => { controller.abort(); adapter.disconnect(); };
  }, [adapter]);

  useEffect(() => {
    if (snapshot.phase !== 'playing') {
      setExitAction(null);
      return;
    }
    const warnBeforeUnload = (event: BeforeUnloadEvent) => {
      event.preventDefault();
      event.returnValue = '';
    };
    window.addEventListener('beforeunload', warnBeforeUnload);
    return () => window.removeEventListener('beforeunload', warnBeforeUnload);
  }, [snapshot.phase]);

  const run = (action: () => void | Promise<void>) => {
    if (busy) return;
    setBusy(true);
    useGameStore.getState().update({ error: null });
    void Promise.resolve().then(action).catch((error: unknown) => {
      useGameStore.getState().update({ error: error instanceof Error ? error.message : String(error) });
    }).finally(() => setBusy(false));
  };

  const disconnect = () => {
    adapter.disconnect();
    useGameStore.getState().update({ phase: 'login', connection: { kind: 'closed', reason: 'Đã ngắt kết nối' }, rooms: [], players: [], ownId: null, pendingRequest: null, skillInvoke: null, fakeSkills: [], regularSkills: [], initialGeneral: null, result: null, board: emptyBoard(), progress: '', error: null });
  };

  const shellVariant = snapshot.phase === 'playing'
    ? 'shell-playing sg-app-shell sg-game-shell'
    : snapshot.phase === 'lobby'
    ? 'sg-app-shell sg-lobby-shell'
    : snapshot.phase === 'room'
    ? 'sg-app-shell sg-room-shell'
    : snapshot.phase === 'boot'
    ? 'sg-app-shell sg-boot-shell'
    : snapshot.phase === 'login'
    ? 'sg-app-shell sg-login-shell'
    : 'sg-app-shell';

  return (
    <main className={`shell ${shellVariant}`}>
      <header className="app-header">
        <div><span className="eyebrow">TQS · Quốc Chiến</span><h1>Tam Quốc Sát <em>Mobile</em></h1><p className="intro">Chiến trường Quốc Chiến trên trình duyệt.</p></div>
        <span className={`status ${snapshot.connection.kind === 'online' ? 'connected' : ''}`}>{snapshot.connection.kind === 'online' ? 'Đã kết nối' : snapshot.connection.kind === 'authenticating' ? 'Đang xác thực' : 'Chưa kết nối'}</span>
      </header>
      {!networkOnline && <p className="notice" role="status">Bạn đang ngoại tuyến. Kết nối mạng để đăng nhập hoặc tiếp tục ván.</p>}
      <BootScreen phase={snapshot.phase} progress={snapshot.progress} error={snapshot.error}
        retry={() => run(() => adapter.boot())} />
      {exitAction && snapshot.phase === 'playing' && <section className="panel" role="alertdialog" aria-labelledby="exit-title" aria-describedby="exit-warning">
        <h2 id="exit-title">Ván vẫn đang chạy</h2>
        <p id="exit-warning">Rời trận hoặc ngắt kết nối khi còn sống có thể khiến máy chủ tạm chặn IP. Nếu cần tạm nghỉ, hãy bật BOT chơi hộ và giữ trang mở.</p>
        <div className="inline-controls">
          <button className="button primary" disabled={busy} onClick={() => setExitAction(null)}>Tiếp tục ván</button>
          {!trusting && <button className="button secondary" disabled={busy} onClick={() => { setExitAction(null); run(() => adapter.toggleTrust()); }}>BOT chơi hộ</button>}
          <button className="button ghost" disabled={busy} onClick={() => {
            const action = exitAction;
            setExitAction(null);
            run(() => action === 'leave' ? adapter.leaveRoom() : disconnect());
          }}>{exitAction === 'leave' ? 'Vẫn rời trận' : 'Vẫn ngắt kết nối'}</button>
        </div>
      </section>}
      {snapshot.phase === 'playing' && !trusting && <RequestDeadline request={snapshot.pendingRequest} />}
      {snapshot.phase === 'login' && <LoginScreen adapter={adapter} run={run} busy={busy} />}
      {snapshot.phase === 'lobby' && <LobbyScreen adapter={adapter} run={run} busy={busy} />}
      {snapshot.phase === 'room' && snapshot.result && <GameResultPanel result={snapshot.result} busy={busy}
        leave={() => run(() => adapter.leaveRoom())} />}
      {snapshot.phase === 'room' && <WaitingRoomScreen adapter={adapter} run={run} busy={busy} />}
      {snapshot.phase === 'playing' && <GameBoardScreen busy={busy} leave={() => setExitAction('leave')}
        toggleTrust={() => run(() => adapter.toggleTrust())}
        regularSkills={snapshot.regularSkills}
        prelightSkill={(skillName, prelight) => run(() => adapter.prelightSkill(skillName, prelight))}
        direct={(id, data) => {
          const request = snapshot.pendingRequest;
          if (request && GAMEPLAY_REQUESTS.has(request.command)) run(() => {
            adapter.finishDirectInteraction(request.requestId, id, data);
          });
        }}
        dispatch={(type, id, action, data) => {
          const request = snapshot.pendingRequest;
          if (request && GAMEPLAY_REQUESTS.has(request.command))
            run(() => adapter.updateRequestUI(request.requestId, type, id, action, data));
        }} />}
      {!trusting && snapshot.pendingRequest?.command === 'AskForSkillInvoke' && <SkillInvokePanel busy={busy} request={snapshot.pendingRequest} prompt={snapshot.skillInvoke}
        onRespond={(choice) => run(() => adapter.sendUiAction(snapshot.pendingRequest!.requestId, choice))} />}
      {!trusting && snapshot.pendingRequest && ['AskForChoices', 'AskForOptions'].includes(snapshot.pendingRequest.command) && snapshot.pendingRequest.choicePrompt &&
        <ChoicePanel key={`${snapshot.pendingRequest.requestId}-${snapshot.pendingRequest.receivedAt}`}
          busy={busy} request={snapshot.pendingRequest} prompt={snapshot.pendingRequest.choicePrompt}
          respond={(selected) => run(() => adapter.respondToChoices(snapshot.pendingRequest!.requestId, selected))} />}
      {!trusting && snapshot.pendingRequest?.cardSelectionPrompt &&
        <CardSelectionPanel key={`${snapshot.pendingRequest.requestId}-${snapshot.pendingRequest.receivedAt}`}
          request={snapshot.pendingRequest} prompt={snapshot.pendingRequest.cardSelectionPrompt} busy={busy}
          view={(selected) => adapter.getCardSelectionView(snapshot.pendingRequest!.requestId, selected)}
          respond={(selected, cancel) => run(() => adapter.respondToCardSelection(snapshot.pendingRequest!.requestId, selected, cancel))} />}
      {!trusting && snapshot.pendingRequest?.cardsAndChoicePrompt &&
        <CardsAndChoicePanel key={`${snapshot.pendingRequest.requestId}-${snapshot.pendingRequest.receivedAt}`}
          request={snapshot.pendingRequest} prompt={snapshot.pendingRequest.cardsAndChoicePrompt} busy={busy}
          view={(selected) => adapter.getCardsAndChoiceView(snapshot.pendingRequest!.requestId, selected)}
          respond={(selected, choice, cancel) => run(() => adapter.respondToCardsAndChoice(snapshot.pendingRequest!.requestId, selected, choice, cancel))} />}
      {!trusting && snapshot.pendingRequest?.nativeDialogPrompt &&
        <NativeDialogPanel key={`${snapshot.pendingRequest.requestId}-${snapshot.pendingRequest.receivedAt}`}
          request={snapshot.pendingRequest} prompt={snapshot.pendingRequest.nativeDialogPrompt} busy={busy}
          chooseGeneral={(token) => run(() => adapter.selectNativeGeneral(snapshot.pendingRequest!.requestId, token))}
          view={() => adapter.getNativeDialogView(snapshot.pendingRequest!.requestId)}
          move={(token, area, index) => run(() => adapter.moveNativeDialogCard(snapshot.pendingRequest!.requestId, token, area, index))}
          respond={(token, cancel) => run(() => adapter.respondToNativeDialog(snapshot.pendingRequest!.requestId, token, cancel))} />}
      {!trusting && snapshot.pendingRequest?.command === 'CustomDialog' && snapshot.initialGeneral &&
        <InitialGeneralPanel key={`${snapshot.pendingRequest.requestId}-${snapshot.pendingRequest.receivedAt}`} adapter={adapter} run={run} busy={busy}
          request={snapshot.pendingRequest} prompt={snapshot.initialGeneral} />}
      {!trusting && snapshot.pendingRequest && snapshot.pendingRequest.command !== 'AskForSkillInvoke' &&
        !GAMEPLAY_REQUESTS.has(snapshot.pendingRequest.command) &&
        !snapshot.pendingRequest.nativeDialogPrompt &&
        !snapshot.pendingRequest.cardSelectionPrompt &&
        !snapshot.pendingRequest.cardsAndChoicePrompt &&
        !(snapshot.pendingRequest.command === 'CustomDialog' && snapshot.initialGeneral) &&
        !(['AskForChoices', 'AskForOptions'].includes(snapshot.pendingRequest.command) && snapshot.pendingRequest.choicePrompt) &&
        <div className="notice error-notice" role="alert">Máy chủ đang chờ phản hồi: {snapshot.pendingRequest.command}. Bộ điều khiển gameplay chưa hỗ trợ yêu cầu này.</div>}
      {snapshot.connection.kind === 'online' && <footer className="footer"><span>{snapshot.manifest?.fileCount ?? 0} tệp đã xác minh</span><button className="button ghost" disabled={busy} onClick={() => snapshot.phase === 'playing' ? setExitAction('disconnect') : run(disconnect)}>Ngắt kết nối</button></footer>}
    </main>
  );
}
