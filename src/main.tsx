import {StrictMode} from 'react';
import {createRoot} from 'react-dom/client';
import App from './App.tsx';
import ErrorBoundary from './components/ErrorBoundary.tsx';
import './index.css';
import { registerSW } from './utils/swRegister';

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
    registerSW();
  });
}
