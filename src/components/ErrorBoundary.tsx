import React, { Component, ErrorInfo, ReactNode } from 'react';
import { AlertTriangle } from 'lucide-react';

interface Props {
  children?: ReactNode;
}

interface State {
  hasError: boolean;
  error: Error | null;
}

export default class ErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
    error: null
  };

  public static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('Uncaught error:', error, errorInfo);
  }

  public render() {
    if (this.state.hasError) {
      let errorMessage = this.state.error?.message || 'Đã xảy ra lỗi không xác định.';
      let isFirestoreError = false;

      try {
        // Try to parse as FirestoreErrorInfo
        const parsed = JSON.parse(errorMessage);
        if (parsed && parsed.operationType) {
          isFirestoreError = true;
          if (parsed.error.includes('Missing or insufficient permissions')) {
            errorMessage = 'Bạn không có quyền thực hiện thao tác này. Vui lòng đăng nhập hoặc liên hệ quản trị viên.';
          } else {
            errorMessage = parsed.error;
          }
        }
      } catch (e) {
        // Not a JSON error string, keep original message
      }

      return (
        <div className="min-h-[400px] flex items-center justify-center p-4">
          <div className="bg-white dark:bg-zinc-900 border border-red-500/30 rounded-2xl p-8 max-w-md w-full text-center shadow-2xl shadow-red-900/20">
            <div className="w-16 h-16 bg-red-500/10 rounded-full flex items-center justify-center mx-auto mb-6">
              <AlertTriangle className="h-8 w-8 text-red-500" />
            </div>
            <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-3">Đã xảy ra lỗi!</h2>
            <p className="text-gray-500 dark:text-zinc-400 text-sm mb-6 leading-relaxed">
              {errorMessage}
            </p>
            <button
              className="bg-red-600 hover:bg-red-700 text-white font-bold py-2.5 px-6 rounded-xl transition-colors w-full"
              onClick={() => {
                this.setState({ hasError: false, error: null });
                window.location.reload();
              }}
            >
              Tải lại trang
            </button>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}
