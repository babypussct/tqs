export default function Footer() {
  return (
    <footer className="bg-white dark:bg-zinc-950 border-t border-gray-200 dark:border-zinc-800 pt-16 pb-8 mt-auto transition-colors duration-200">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-12 mb-12">
          <div className="col-span-1 md:col-span-2">
            <span className="text-2xl font-black tracking-tighter text-red-600 dark:text-red-500 uppercase mb-4 block">TQS<span className="text-gray-900 dark:text-white">Store</span></span>
            <p className="text-gray-500 dark:text-zinc-400 max-w-sm mb-6">
              Hệ thống phân phối boardgame Tam Quốc Sát chính hãng lớn nhất Việt Nam. Cam kết chất lượng, đóng gói chuẩn sưu tầm.
            </p>
          </div>
          <div>
            <h4 className="text-gray-900 dark:text-white font-bold mb-4 uppercase tracking-wider text-sm">Danh Mục</h4>
            <ul className="space-y-3 text-gray-500 dark:text-zinc-400 text-sm">
              <li><a href="#" className="hover:text-red-600 dark:hover:text-red-400 transition-colors">Bản Cơ Bản</a></li>
              <li><a href="#" className="hover:text-red-600 dark:hover:text-red-400 transition-colors">Bản Mở Rộng</a></li>
              <li><a href="#" className="hover:text-red-600 dark:hover:text-red-400 transition-colors">Quốc Chiến</a></li>
              <li><a href="#" className="hover:text-amber-600 dark:hover:text-amber-500 transition-colors font-medium">Phụ Kiện & Sleeves</a></li>
            </ul>
          </div>
          <div>
            <h4 className="text-gray-900 dark:text-white font-bold mb-4 uppercase tracking-wider text-sm">Chính Sách</h4>
            <ul className="space-y-3 text-gray-500 dark:text-zinc-400 text-sm">
              <li><a href="#" className="hover:text-gray-900 dark:hover:text-white transition-colors">Chính sách bảo hành</a></li>
              <li><a href="#" className="hover:text-gray-900 dark:hover:text-white transition-colors">Chính sách đổi trả (Anti-Móp)</a></li>
              <li><a href="#" className="hover:text-gray-900 dark:hover:text-white transition-colors">Giao hàng & Thanh toán</a></li>
              <li><a href="#" className="hover:text-gray-900 dark:hover:text-white transition-colors">Hướng dẫn luật chơi</a></li>
            </ul>
          </div>
        </div>
        <div className="border-t border-gray-200 dark:border-zinc-800 pt-8 flex flex-col md:flex-row justify-between items-center gap-4">
          <p className="text-gray-400 dark:text-zinc-500 text-sm">© 2024 TQS Store. All rights reserved.</p>
          <div className="flex items-center gap-4 text-gray-400 dark:text-zinc-500 text-sm">
            <span>Đóng gói chuẩn sưu tầm.</span>
            <span>Hoàn tiền nếu móp hộp.</span>
          </div>
        </div>
      </div>
    </footer>
  );
}
