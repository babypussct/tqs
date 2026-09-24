import { ArrowLeft, ArrowRight, CheckCircle2, Clock3, ShieldCheck, Truck } from 'lucide-react';
import { Link, useParams } from 'react-router-dom';

interface SupportSection {
  title: string;
  body: string;
  bullets?: string[];
}

interface SupportPageContent {
  eyebrow: string;
  title: string;
  intro: string;
  icon: typeof ShieldCheck;
  sections: SupportSection[];
}

const SUPPORT_PAGES: Record<string, SupportPageContent> = {
  warranty: {
    eyebrow: 'An tâm mua sắm',
    title: 'Chính sách bảo hành',
    intro: 'TQS Store đồng hành cùng bạn trong suốt quá trình sử dụng sản phẩm. Nếu có vấn đề, hãy liên hệ để được hỗ trợ nhanh nhất.',
    icon: ShieldCheck,
    sections: [
      {
        title: 'Phạm vi hỗ trợ',
        body: 'Sản phẩm được kiểm tra trước khi đóng gói. TQS hỗ trợ các lỗi do nhà sản xuất, thiếu linh kiện hoặc sai sản phẩm so với đơn hàng.',
        bullets: ['Báo lỗi trong vòng 7 ngày kể từ khi nhận hàng.', 'Gửi ảnh hoặc video tình trạng sản phẩm để đội ngũ kiểm tra.', 'Không áp dụng cho hư hỏng do sử dụng sai hướng dẫn hoặc tự ý thay đổi sản phẩm.'],
      },
      {
        title: 'Cách gửi yêu cầu',
        body: 'Vui lòng giữ lại mã đơn hàng và liên hệ qua hotline hoặc email hiển thị ở cuối trang. Đội ngũ hỗ trợ sẽ phản hồi trong giờ làm việc.',
      },
    ],
  },
  returns: {
    eyebrow: 'Đóng gói chuẩn sưu tầm',
    title: 'Chính sách đổi trả Anti-Móp',
    intro: 'Mỗi đơn hàng đều được bọc chống sốc và đặt trong carton cứng. Nếu kiện hàng bị móp hoặc hư hỏng khi vận chuyển, TQS sẽ cùng bạn xử lý đến khi ổn thỏa.',
    icon: CheckCircle2,
    sections: [
      {
        title: 'Khi nhận hàng',
        body: 'Bạn nên quay video mở kiện liên tục từ lúc bao bì còn nguyên. Đây là căn cứ nhanh nhất để TQS làm việc với đơn vị vận chuyển.',
        bullets: ['Kiểm tra tình trạng hộp và số lượng sản phẩm.', 'Từ chối nhận nếu kiện có dấu hiệu rách, ướt hoặc biến dạng nghiêm trọng.', 'Gửi hình ảnh/video trong vòng 24 giờ nếu phát hiện vấn đề.'],
      },
      {
        title: 'Điều kiện đổi trả',
        body: 'Sản phẩm cần còn đầy đủ phụ kiện, quà tặng và chưa có dấu hiệu đã sử dụng. Với sản phẩm lỗi hoặc giao sai, TQS hỗ trợ đổi sản phẩm tương đương hoặc hoàn tiền theo thỏa thuận.',
      },
    ],
  },
  shipping: {
    eyebrow: 'Nhanh chóng & minh bạch',
    title: 'Giao hàng & thanh toán',
    intro: 'TQS giao hàng toàn quốc với nhiều lựa chọn thanh toán để bạn dễ dàng hoàn tất đơn hàng.',
    icon: Truck,
    sections: [
      {
        title: 'Thời gian giao dự kiến',
        body: 'Đơn nội thành Hà Nội thường nhận trong 1–2 ngày làm việc. Các tỉnh thành khác thường mất 2–5 ngày, tùy khu vực và đơn vị vận chuyển.',
        bullets: ['Đơn được xử lý trong giờ làm việc từ thứ 2 đến thứ 7.', 'Thời gian có thể thay đổi trong dịp lễ hoặc thời tiết bất lợi.', 'Bạn có thể theo dõi mã vận đơn trong hồ sơ sau khi đơn được gửi.'],
      },
      {
        title: 'Phương thức thanh toán',
        body: 'TQS hỗ trợ thanh toán khi nhận hàng (COD) và chuyển khoản VietQR. Với đơn VietQR, vui lòng giữ lại xác nhận giao dịch để được đối soát nhanh hơn.',
      },
    ],
  },
  'how-to-play': {
    eyebrow: 'Bắt đầu cuộc chơi',
    title: 'Hướng dẫn luật chơi cơ bản',
    intro: 'Chưa quen boardgame Tam Quốc Sát? Bắt đầu với vài nguyên tắc nền tảng dưới đây, sau đó khám phá chi tiết trong tờ hướng dẫn đi kèm bộ game.',
    icon: Clock3,
    sections: [
      {
        title: 'Chuẩn bị',
        body: 'Mỗi người chọn một tướng, nhận số máu theo thẻ tướng và rút bài khởi đầu theo hướng dẫn của phiên bản bạn đang chơi.',
        bullets: ['Xáo riêng bộ bài cơ bản và các bộ mở rộng nếu có.', 'Đặt thẻ tướng ngửa để mọi người cùng theo dõi.', 'Thống nhất người đi đầu trước khi bắt đầu.'],
      },
      {
        title: 'Một lượt chơi',
        body: 'Mỗi lượt thường gồm các bước: bắt đầu lượt, rút bài, hành động và kết thúc lượt. Hãy đọc điều kiện trên từng lá bài trước khi sử dụng.',
        bullets: ['Tôn trọng thứ tự lượt và giới hạn số lá bài được dùng.', 'Khi có tranh chấp luật, ưu tiên nội dung trong sách hướng dẫn của phiên bản đang chơi.', 'Bạn có thể liên hệ TQS nếu cần giải đáp tình huống cụ thể.'],
      },
    ],
  },
};

export default function SupportPage() {
  const { topic } = useParams();
  const page = topic ? SUPPORT_PAGES[topic] : undefined;

  if (!page) {
    return (
      <div className="max-w-3xl mx-auto px-4 sm:px-6 py-24 text-center">
        <h1 className="text-3xl font-black text-gray-900 dark:text-white">Không tìm thấy nội dung</h1>
        <p className="mt-3 text-gray-500 dark:text-zinc-400">Trang hỗ trợ bạn đang tìm không tồn tại.</p>
        <Link to="/" className="inline-flex items-center gap-2 mt-8 text-red-600 font-semibold hover:text-red-700">
          <ArrowLeft className="w-4 h-4" /> Về trang chủ
        </Link>
      </div>
    );
  }

  const Icon = page.icon;

  return (
    <div className="bg-gray-50 dark:bg-zinc-950 min-h-full transition-colors">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12 sm:py-16">
        <Link to="/" className="inline-flex items-center gap-2 text-sm font-medium text-gray-500 dark:text-zinc-400 hover:text-red-600 transition-colors">
          <ArrowLeft className="w-4 h-4" /> Trang chủ
        </Link>

        <article className="mt-8 bg-white dark:bg-zinc-900 border border-gray-200 dark:border-zinc-800 rounded-3xl shadow-sm overflow-hidden">
          <div className="p-7 sm:p-10 border-b border-gray-100 dark:border-zinc-800 bg-gradient-to-br from-red-50 via-white to-amber-50 dark:from-red-950/30 dark:via-zinc-900 dark:to-amber-950/20">
            <div className="w-12 h-12 rounded-2xl bg-red-100 dark:bg-red-500/15 text-red-600 dark:text-red-400 flex items-center justify-center mb-6">
              <Icon className="w-6 h-6" />
            </div>
            <p className="text-xs font-bold uppercase tracking-[0.2em] text-red-600 dark:text-red-400">{page.eyebrow}</p>
            <h1 className="mt-3 text-3xl sm:text-4xl font-black tracking-tight text-gray-900 dark:text-white">{page.title}</h1>
            <p className="mt-4 max-w-2xl text-base leading-7 text-gray-600 dark:text-zinc-300">{page.intro}</p>
          </div>

          <div className="p-7 sm:p-10 space-y-9">
            {page.sections.map((section) => (
              <section key={section.title}>
                <h2 className="text-xl font-bold text-gray-900 dark:text-white">{section.title}</h2>
                <p className="mt-3 leading-7 text-gray-600 dark:text-zinc-300">{section.body}</p>
                {section.bullets && (
                  <ul className="mt-4 space-y-3">
                    {section.bullets.map((bullet) => (
                      <li key={bullet} className="flex items-start gap-3 text-sm leading-6 text-gray-600 dark:text-zinc-300">
                        <CheckCircle2 className="w-5 h-5 shrink-0 mt-0.5 text-emerald-500" />
                        <span>{bullet}</span>
                      </li>
                    ))}
                  </ul>
                )}
              </section>
            ))}
          </div>

          <div className="p-7 sm:p-10 pt-0">
            <Link to="/shop" className="inline-flex items-center justify-center gap-2 rounded-xl bg-red-600 px-5 py-3 text-sm font-bold text-white shadow-sm transition hover:bg-red-700">
              Khám phá sản phẩm <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </article>
      </div>
    </div>
  );
}
