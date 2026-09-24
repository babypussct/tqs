import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.tsx';
import ErrorBoundary from './components/ErrorBoundary.tsx';
import './index.css';
import { registerSW, unregisterAllSW } from './utils/swRegister';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <ErrorBoundary>
      <App />
    </ErrorBoundary>
  </StrictMode>,
);

// Đăng ký Service Worker sau khi app render xong (không block)
// SW chỉ active trên HTTPS và localhost
if (typeof window !== 'undefined') {
  window.addEventListener('load', () => {
    if (import.meta.env.PROD) {
      registerSW();
    } else {
      // Không để service worker của bản production can thiệp vào Vite/HMR
      // trong lúc phát triển local.
      unregisterAllSW();
    }
  }, { once: true });
}
