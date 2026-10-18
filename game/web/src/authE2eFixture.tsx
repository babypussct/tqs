/** Local browser fixture: load the real App/LoginScreen while bypassing the
 * unrelated FreeKill asset boot. Firebase popup is exercised without signing
 * into any real account. This entry is not included in the production build. */
import { createRoot } from 'react-dom/client';
import { GameAdapter } from './engine/gameAdapter';
import { useGameStore } from './store/gameStore';
import './styles.css';

GameAdapter.prototype.boot = async () => {
  useGameStore.getState().update({ phase: 'login', error: null });
};

void import('./App').then(({ default: App }) => {
  createRoot(document.getElementById('root')!).render(<App />);
});
