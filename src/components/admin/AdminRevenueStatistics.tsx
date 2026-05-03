import React, { useState, useMemo } from 'react';
import { useOrders } from '../../utils/useOrders';
import { DollarSign, TrendingUp, Package, Truck, Wallet, FileBarChart, ArrowDownRight, ArrowUpRight, Coins } from 'lucide-react';
import { Order } from '../../types';

export default function AdminRevenueStatistics() {
  const { orders, loading } = useOrders();
  const [dateFilter, setDateFilter] = useState<'all' | 'thisMonth' | 'lastMonth'>('all');

  const stats = useMemo(() => {
    const now = new Date();
    const currentMonth = now.getMonth();
    const currentYear = now.getFullYear();
    const lastMonth = currentMonth === 0 ? 11 : currentMonth - 1;
    const lastMonthYear = currentMonth === 0 ? currentYear - 1 : currentYear;

    // Lọc ra các đơn hàng ĐÃ GIAO THÀNH CÔNG
    const deliveredOrders = orders.filter(o => o.status === 'delivered');

    // Lọc theo thời gian
    const filteredOrders = deliveredOrders.filter(o => {
      if (dateFilter === 'all') return true;
      const orderDate = o.createdAt?.toDate();
      if (!orderDate) return false;
      
      const oMonth = orderDate.getMonth();
      const oYear = orderDate.getFullYear();

      if (dateFilter === 'thisMonth') {
        return oMonth === currentMonth && oYear === currentYear;
      }
      if (dateFilter === 'lastMonth') {
        return oMonth === lastMonth && oYear === lastMonthYear;
      }
      return true;
    });

    let grossRevenue = 0; // Doanh thu thu từ khách (finalAmount)
    let shippingRevenue = 0; // Phí ship thu từ khách
    let actualShippingCost = 0; // Phí ship trả ĐVVC
    let baseCost = 0; // Giá vốn hàng bán
    let packagingCost = 0; // Tiền hộp/đóng gói
    let totalDiscount = 0; // Khuyến mãi (để tham khảo)

    let ordersWithMissingCosts = 0;

    filteredOrders.forEach(o => {
      grossRevenue += o.finalAmount || o.totalAmount || 0;
      shippingRevenue += o.shippingFee || 0;
      totalDiscount += o.discountAmount || 0;
      
      actualShippingCost += o.actualShippingCost || 0;
      baseCost += o.baseCost || 0;
      packagingCost += o.packagingCost || 0;

      if ((o.actualShippingCost === undefined || o.actualShippingCost === null) || 
          (o.baseCost === undefined || o.baseCost === null)) {
        ordersWithMissingCosts++;
      }
    });

    const totalCosts = actualShippingCost + baseCost + packagingCost;
    const netRevenue = grossRevenue - totalCosts;
    const shippingProfit = shippingRevenue - actualShippingCost;

    return {
      orderCount: filteredOrders.length,
      grossRevenue,
      shippingRevenue,
      actualShippingCost,
      shippingProfit,
      baseCost,
      packagingCost,
      totalDiscount,
      totalCosts,
      netRevenue,
      ordersWithMissingCosts
    };
  }, [orders, dateFilter]);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-20">
        <div className="w-6 h-6 border-2 border-indigo-600 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header & Filter */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white dark:bg-zinc-900 p-5 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm">
        <div>
          <h2 className="text-lg font-bold text-slate-900 dark:text-white flex items-center gap-2">
            <FileBarChart className="w-5 h-5 text-indigo-600 dark:text-indigo-400" /> 
            Báo cáo Doanh thu Thực tế
          </h2>
          <p className="text-sm text-slate-500 dark:text-zinc-400 mt-1">Chỉ thống kê trên các đơn hàng có trạng thái "Đã giao"</p>
        </div>
        <select
          value={dateFilter}
          onChange={(e) => setDateFilter(e.target.value as any)}
          className="bg-slate-50 dark:bg-zinc-800 border border-slate-200 dark:border-zinc-700 text-slate-700 dark:text-zinc-200 text-sm font-semibold px-4 py-2 rounded-lg outline-none cursor-pointer focus:ring-2 focus:ring-indigo-500 transition-shadow"
        >
          <option value="all">Toàn thời gian</option>
          <option value="thisMonth">Tháng này</option>
          <option value="lastMonth">Tháng trước</option>
        </select>
      </div>

      {stats.ordersWithMissingCosts > 0 && (
        <div className="bg-amber-50 dark:bg-amber-500/10 border border-amber-200 dark:border-amber-500/20 p-4 rounded-xl flex items-start gap-3">
          <div className="mt-0.5">
            <div className="w-2 h-2 rounded-full bg-amber-500 animate-pulse"></div>
          </div>
          <div>
            <h4 className="font-bold text-amber-800 dark:text-amber-400 text-sm">Chưa nhập đủ dữ liệu chi phí</h4>
            <p className="text-xs text-amber-700 dark:text-amber-500 mt-0.5">
              Có <span className="font-bold">{stats.ordersWithMissingCosts} đơn hàng</span> đã giao nhưng chưa được nhập <span className="underline">Giá vốn</span> hoặc <span className="underline">Phí ship thực tế</span>. Lợi nhuận (Net Revenue) dưới đây có thể cao hơn thực tế. Hãy vào mục Quản lý Đơn hàng để bổ sung!
            </p>
          </div>
        </div>
      )}

      {/* Main KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Gross Revenue */}
        <div className="bg-white dark:bg-zinc-900 p-6 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="w-10 h-10 rounded-lg bg-blue-50 dark:bg-blue-500/10 flex items-center justify-center">
              <DollarSign className="w-5 h-5 text-blue-600 dark:text-blue-400" />
            </div>
            <span className="text-xs font-bold px-2.5 py-1 bg-slate-100 dark:bg-zinc-800 text-slate-600 dark:text-zinc-400 rounded-full">{stats.orderCount} đơn</span>
          </div>
          <p className="text-sm font-semibold text-slate-500 dark:text-zinc-400 mb-1">Doanh thu Thu vào (Gross)</p>
          <h3 className="text-2xl lg:text-3xl font-black text-slate-900 dark:text-white tracking-tight">
            {stats.grossRevenue.toLocaleString('vi-VN')} đ
          </h3>
          <p className="text-xs text-slate-400 mt-2">Tổng tiền khách đã thanh toán</p>
        </div>

        {/* Total Costs */}
        <div className="bg-white dark:bg-zinc-900 p-6 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div className="w-10 h-10 rounded-lg bg-red-50 dark:bg-red-500/10 flex items-center justify-center">
              <TrendingUp className="w-5 h-5 text-red-600 dark:text-red-400 rotate-180" />
            </div>
          </div>
          <p className="text-sm font-semibold text-slate-500 dark:text-zinc-400 mb-1">Tổng Chi phí</p>
          <h3 className="text-2xl lg:text-3xl font-black text-red-600 dark:text-red-400 tracking-tight">
            -{stats.totalCosts.toLocaleString('vi-VN')} đ
          </h3>
          <p className="text-xs text-slate-400 mt-2">Bao gồm giá vốn, phí vận chuyển, đóng gói</p>
        </div>

        {/* Net Revenue */}
        <div className="bg-gradient-to-br from-indigo-600 to-indigo-800 dark:from-indigo-900 dark:to-zinc-900 p-6 border border-indigo-500/30 rounded-xl shadow-lg relative overflow-hidden">
          <div className="absolute top-0 right-0 p-4 opacity-10">
            <Wallet className="w-24 h-24 text-white" />
          </div>
          <div className="relative z-10">
            <div className="flex items-center justify-between mb-4">
              <div className="w-10 h-10 rounded-lg bg-white/20 flex items-center justify-center backdrop-blur-sm">
                <TrendingUp className="w-5 h-5 text-white" />
              </div>
            </div>
            <p className="text-sm font-semibold text-indigo-100 mb-1">Lợi nhuận (Net Revenue)</p>
            <h3 className="text-2xl lg:text-3xl font-black text-white tracking-tight">
              {stats.netRevenue.toLocaleString('vi-VN')} đ
            </h3>
            <p className="text-xs text-indigo-200 mt-2">Số tiền thực lãi mang về</p>
          </div>
        </div>
      </div>

      {/* Breakdown Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        
        {/* Logistics Breakdown */}
        <div className="bg-white dark:bg-zinc-900 p-6 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm">
          <h3 className="text-base font-bold text-slate-900 dark:text-white mb-5 flex items-center gap-2 border-b border-slate-100 dark:border-zinc-800 pb-3">
            <Truck className="w-4 h-4 text-emerald-500" /> Phân tích Vận chuyển
          </h3>
          
          <div className="space-y-4">
            <div className="flex items-center justify-between p-3 bg-slate-50 dark:bg-zinc-800/50 rounded-lg">
              <span className="text-sm font-medium text-slate-600 dark:text-zinc-400">Thu phí ship từ khách</span>
              <span className="text-sm font-bold text-slate-900 dark:text-white">+{stats.shippingRevenue.toLocaleString('vi-VN')} đ</span>
            </div>
            <div className="flex items-center justify-between p-3 bg-slate-50 dark:bg-zinc-800/50 rounded-lg">
              <span className="text-sm font-medium text-slate-600 dark:text-zinc-400">Trả phí ship thực tế cho ĐVVC</span>
              <span className="text-sm font-bold text-red-600 dark:text-red-400">-{stats.actualShippingCost.toLocaleString('vi-VN')} đ</span>
            </div>
            
            <div className="flex items-center justify-between p-4 bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-100 dark:border-emerald-500/20 rounded-xl">
              <span className="text-sm font-bold text-emerald-800 dark:text-emerald-400">Lỗ/Lãi từ Vận chuyển</span>
              <div className={`flex items-center gap-1 font-bold ${stats.shippingProfit >= 0 ? 'text-emerald-600' : 'text-rose-600'}`}>
                {stats.shippingProfit >= 0 ? <ArrowUpRight className="w-4 h-4" /> : <ArrowDownRight className="w-4 h-4" />}
                {Math.abs(stats.shippingProfit).toLocaleString('vi-VN')} đ
              </div>
            </div>
          </div>
        </div>

        {/* Goods Cost Breakdown */}
        <div className="bg-white dark:bg-zinc-900 p-6 border border-slate-200 dark:border-zinc-800 rounded-xl shadow-sm">
          <h3 className="text-base font-bold text-slate-900 dark:text-white mb-5 flex items-center gap-2 border-b border-slate-100 dark:border-zinc-800 pb-3">
            <Package className="w-4 h-4 text-orange-500" /> Phân tích Hàng hóa
          </h3>
          
          <div className="space-y-4">
            <div className="flex items-center justify-between p-3 bg-slate-50 dark:bg-zinc-800/50 rounded-lg">
              <span className="text-sm font-medium text-slate-600 dark:text-zinc-400 flex items-center gap-2">
                <Coins className="w-4 h-4 text-slate-400" /> Tổng Giá vốn (COGS)
              </span>
              <span className="text-sm font-bold text-orange-600 dark:text-orange-400">-{stats.baseCost.toLocaleString('vi-VN')} đ</span>
            </div>
            <div className="flex items-center justify-between p-3 bg-slate-50 dark:bg-zinc-800/50 rounded-lg">
              <span className="text-sm font-medium text-slate-600 dark:text-zinc-400 flex items-center gap-2">
                <Box className="w-4 h-4 text-slate-400" /> Chi phí đóng gói (Hộp/Mút)
              </span>
              <span className="text-sm font-bold text-orange-600 dark:text-orange-400">-{stats.packagingCost.toLocaleString('vi-VN')} đ</span>
            </div>
            <div className="flex items-center justify-between p-3 bg-slate-50 dark:bg-zinc-800/50 rounded-lg opacity-60">
              <span className="text-sm font-medium text-slate-600 dark:text-zinc-400">Mã giảm giá đã trợ giá cho khách</span>
              <span className="text-sm font-bold text-slate-600 dark:text-slate-400">({stats.totalDiscount.toLocaleString('vi-VN')} đ)</span>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}
