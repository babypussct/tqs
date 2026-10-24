import React from 'react';
import { createRoot } from 'react-dom/client';
import App from './App';
import './styles.css';

const initialUrl = new URL(location.href);
if (initialUrl.searchParams.has('tqs-update')) {
  initialUrl.searchParams.delete('tqs-update');
  history.replaceState(history.state, '', initialUrl.href);
}

createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
