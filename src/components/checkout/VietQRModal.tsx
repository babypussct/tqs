import React from 'react';
import { Copy, CheckCircle2 } from 'lucide-react';
import { toast } from 'sonner';

interface VietQRModalProps {
  paymentConfig: any;
  orderFinalAmount: number;
  orderTotalAmount: number;
  createdOrderId: string;
  onConfirm: () => void;
  onLater: () => void;
}

export default function VietQRModal({
  paymentConfig,
  orderFinalAmount,
  orderTotalAmount,
  createdOrderId,
  onConfirm,
  onLater
}: VietQRModalProps) {
  const amountToPay = orderFinalAmount || orderTotalAmount;

  const handleCopy = (text: string, message: string) => {
    navigator.clipboard.writeText(text);
    toast.success(message);
  };

  return (
    <div className="max-w-3xl mx-auto px-4 py-16 sm:px-6 sm:py-24 lg:px-8 text-center animate-in fade-in duration-300">
      <div className="bg-white dark:bg-zinc-900 rounded-2xl p-8 border border-gray-200 dark:border-zinc-800 shadow-sm max-w-md mx-auto">
        <h1 className="text-2xl font-black text-gray-900 dark:text-white tracking-tight mb-2">Thanh toán đơn hàng</h1>
        <p className="text-gray-500 dark:text-zinc-400 mb-6 text-sm">
          Vui lòng quét mã QR bên dưới bằng ứng dụng ngân hàng của bạn để thanh toán.
        </p>
        
        <div className="bg-gray-50 dark:bg-zinc-950 p-4 rounded-xl border border-gray-200 dark:border-zinc-800 mb-6 flex flex-col items-center justify-center">
          <div className="bg-white dark:bg-white p-3 rounded-2xl shadow-sm border border-gray-100 dark:border-zinc-800 flex items-center justify-center w-full max-w-[320px] mx-auto">
            <img 
              src={`https://img.vietqr.io/image/${paymentConfig.bankId}-${paymentConfig.accountNumber}-${paymentConfig.template}.png?amount=${amountToPay}&addInfo=${createdOrderId}&accountName=${encodeURIComponent(paymentConfig.accountName)}`} 
              alt="VietQR" 
              className="w-full h-auto aspect-square object-contain rounded-xl"
            />
          </div>
          
          <div className="w-full mt-6 space-y-3 bg-white dark:bg-zinc-900 p-4 rounded-lg border border-gray-200 dark:border-zinc-800 text-left">
            <div className="flex items-center justify-between text-sm">
              <span className="text-gray-500 dark:text-zinc-400">Ngân hàng:</span>
              <span className="font-bold text-gray-900 dark:text-white">{paymentConfig.bankId}</span>
            </div>
            <div className="flex items-center justify-between text-sm group">
              <span className="text-gray-500 dark:text-zinc-400">Mã đơn (Nội dung):</span>
              <div className="flex items-center gap-2">
                <span className="font-mono font-bold text-blue-600 dark:text-blue-400">{createdOrderId}</span>
                <button onClick={() => handleCopy(createdOrderId, 'Đã copy nội dung')} className="p-1.5 text-gray-400 hover:text-blue-500 hover:bg-blue-50 dark:hover:bg-blue-500/10 rounded transition-colors opacity-0 group-hover:opacity-100 focus:opacity-100">
                  <Copy className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
            <div className="flex items-center justify-between text-sm group">
              <span className="text-gray-500 dark:text-zinc-400">Số tài khoản:</span>
              <div className="flex items-center gap-2">
                <span className="font-mono font-bold text-gray-900 dark:text-white">{paymentConfig.accountNumber}</span>
                <button onClick={() => handleCopy(paymentConfig.accountNumber, 'Đã copy số tài khoản')} className="p-1.5 text-gray-400 hover:text-emerald-500 hover:bg-emerald-50 dark:hover:bg-emerald-500/10 rounded transition-colors opacity-0 group-hover:opacity-100 focus:opacity-100">
                  <Copy className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
            <div className="flex items-center justify-between text-sm group">
              <span className="text-gray-500 dark:text-zinc-400">Số tiền:</span>
              <div className="flex items-center gap-2">
                <span className="font-bold text-red-600 dark:text-red-500">{amountToPay.toLocaleString('vi-VN')}</span>
                <button onClick={() => handleCopy(amountToPay.toString(), 'Đã copy số tiền')} className="p-1.5 text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded transition-colors opacity-0 group-hover:opacity-100 focus:opacity-100">
                  <Copy className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          </div>

          <p className="text-xs text-center text-gray-500 dark:text-zinc-400 mt-4 leading-relaxed font-medium">
            {paymentConfig.paymentNote}
          </p>
        </div>

        <div className="space-y-3">
          <button
            onClick={() => {
              toast.success('Đang chờ xác nhận thanh toán');
              onConfirm();
            }}
            className="w-full bg-emerald-600 hover:bg-emerald-700 text-white px-8 py-3.5 rounded-xl font-bold transition-colors shadow-lg shadow-emerald-600/20 flex items-center justify-center gap-2"
          >
            <CheckCircle2 className="w-5 h-5" /> Tôi đã chuyển khoản
          </button>
          <button
            onClick={onLater}
            className="w-full bg-gray-100 dark:bg-zinc-800 hover:bg-gray-200 dark:hover:bg-zinc-700 text-gray-900 dark:text-white px-8 py-3.5 rounded-xl font-bold transition-colors"
          >
            Thanh toán sau
          </button>
        </div>
      </div>
    </div>
  );
}
