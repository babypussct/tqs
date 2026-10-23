# TQSShop — build độc lập và phát hành có bằng chứng

## Nguyên nhân và cơ chế ngăn tái diễn

Root `dist/` là artifact game legacy còn được Git theo dõi. Khi shop dùng cùng
thư mục này, Vite làm rỗng output trước khi build, dẫn tới hàng nghìn tệp game bị
xóa/ghi đè trong working tree. Shop hiện chỉ ghi `dist-shop/`; game ghi
`game/web/dist/`. Việc bỏ qua `dist/` trong `.gitignore` không bảo vệ những tệp
đã tracked, nên cần kiểm tra trước thao tác xóa/ghi.

- `build/output-policy.mjs` chạy ở hook `configResolved`, trước khi Vite ghi
  output: chặn mọi đích ngoài `dist-shop/`, symlink và output có tệp tracked.
  Gọi trực tiếp `vite build --outDir dist` cũng bị chặn.
- `npm run build` và `npm run clean` đi qua `build/shop.mjs`, kiểm tra đồng bộ
  Vercel và đối chiếu SHA-256 + danh sách tệp của cả hai output game trước/sau.
  Phát hiện khác biệt thì trả lỗi, giữ nguyên hiện trạng để điều tra, không tự
  phục hồi hoặc ghi đè thay đổi của người dùng. Chạy các build tuần tự để bằng
  chứng hash phản ánh đúng từng thao tác.
- `vercel.json` đặt tường minh `buildCommand=npm run build` và
  `outputDirectory=dist-shop`. `.vercelignore` loại cả `dist/` legacy và
  `dist-shop/` local khỏi source upload, nhưng giữ thư mục `build/` cần cho builder.
- TypeScript root chỉ quản lý shop/API/tests/build config. Game app và toàn bộ
  script TypeScript game được kiểm riêng bằng cấu hình của game, giữ `strict`.
  `npm run typecheck:all` tổng hợp cả ba; không quét bản sao trong `scratch/`.
- `.github/workflows/build-safety.yml` cài bằng hai lockfile, chạy regression
  guard, typecheck ba scope, game build, shop build → clean → rebuild và kiểm
  `git diff --exit-code -- dist`. Workflow dùng Node 24 theo cấu hình project
  Vercel đã đọc ngày 19/10/2026, chỉ chạy các job của phạm vi bị ảnh hưởng. Workflow chỉ có hiệu lực trên GitHub sau push;
  required status/branch protection cần cấu hình riêng tại repository.

## Phạm vi pipeline trong cùng repo

`build/change-scopes.mjs` là bộ phân loại dùng chung cho GitHub CI và
`build/vercel-ignore.mjs`. Xem phạm vi của thay đổi local bằng:

```bash
npm run changes:plan
npm run test:pipelines
```

| Thay đổi | CI Shop | CI TQSVN | Vercel Shop |
| --- | --- | --- | --- |
| Shop `src/`, `api/`, `public/`, root package/lock/config | Chạy | Bỏ qua | Build |
| Game `game/`, `runtime/`, gateway và deployment game | Bỏ qua | Chạy | Bỏ qua |
| Contract `src/game/`, `api/game/`, auth server, Firebase config/rules, quyền game, hạ tầng pipeline | Chạy | Chạy | Build |
| Tài liệu/checkpoint và artifact legacy `dist/` | Bỏ qua job ứng dụng | Bỏ qua job ứng dụng | Bỏ qua |
| Đường dẫn mới chưa có mapping hoặc thiếu lịch sử Git | Chạy | Chạy | Build để tránh bỏ sót |

Các ngoại lệ shared được xét trước prefix `src/` và `api/`; không giả định mọi
file ở hai thư mục đó đều chỉ thuộc Shop. Ví dụ `src/game/gamePoolPacks.ts`
được cả game lẫn API Shop import; `firebase-applet-config.json` được game đọc.
Danh sách cụ thể và regression ở `build/change-scopes*.mjs`.

GitHub CI so sánh toàn bộ `before..after` của push; PR dùng merge-base với head.
Đổi tên được đọc như xóa + thêm để không bỏ sót khi chuyển file qua ranh giới.
Job phát hiện phạm vi luôn chạy; job `Pipeline gate` luôn báo trạng thái cuối,
kể cả PR chỉ sửa tài liệu. Khi bật branch protection, yêu cầu **Pipeline gate**;
không dùng top-level path filter khiến required check bị pending vô thời hạn.
CI không chứa bước publish/deploy và không cần credential production.

Job TQSVN chỉ cài dependency game/web + game/gateway. Trước audit/build, nó
chạy `npm --prefix game/web run prepare:upstream`, lấy đúng 14 SHA trong
`upstream-packages.ts`, sparse-checkout source Lua/JSON/MD/QML/JS và cache theo
hash manifest pin. Checkout có SHA sai hoặc đang dirty sẽ báo lỗi và giữ nguyên.
Lệnh này làm rõ dependency source trước đây chỉ tồn tại trong `scratch/upstream`
của máy phát triển. Có thể chạy `prepare:upstream -- --check` để chỉ xác minh.
Lỗi tải Gitee hoặc thiếu pin làm CI FAIL, không bỏ audit để lấy PASS. Hai bản
source gateway legacy `gateway/src` và `game/gateway/src` cùng lockfile phải
khớp nhau trước khi chạy gateway tests, để bản đóng gói được kiểm đúng source.

Vercel dùng SHA deployment thành công trước của cùng project/branch
(`VERCEL_GIT_PREVIOUS_SHA`), không chỉ `HEAD^`, để tránh bỏ sót commit Shop trước
một commit game trong cùng đợt push. Thiếu baseline, shallow history hoặc deploy
CLI thì tiếp tục build. Theo quy ước Vercel: exit **0 = skip**, **1 = build**.
`vercel.json` dùng `node build/vercel-ignore.mjs`. Dashboard đã được đặt bootstrap
ngày 19/10/2026: dùng script versioned khi có, còn trước khi source được push thì
so sánh Git trực tiếp để bỏ qua các cây game/tài liệu đã biết. Bootstrap nằm
trong hằng `bootstrapIgnoreCommand` (250 ký tự, giới hạn Vercel 256), có test thật
trên Git fixture cả khi script chưa tồn tại. Thiết lập build/output dashboard
được giữ nguyên. Thay đổi ignore setting không tạo deployment.

Cloudflare project **tqsvn hiện là Direct Upload, Git Provider = No** (đã đọc bằng
Wrangler ngày 19/10/2026). Giữ chế độ này: push GitHub không tự deploy TQSVN.
Khi phát hành game đã được cho phép, build trong `game/web/` và deploy từ đúng
thư mục đó để Wrangler đọc `wrangler.toml`, Functions và KV binding. Không thêm
workflow tự phát hành hoặc liên kết Git Pages trong thay đổi tách pipeline này.

## Kiểm tra local trước phát hành

Từ root repository, cài dependency khi checkout mới:

```bash
npm ci
npm --prefix game/web ci
```

Chạy tuần tự, dừng khi bất kỳ lệnh nào lỗi:

```bash
git status --short
npm run test:build-safety
npm run check:build
npm run typecheck:all
npm --prefix game/web run build
npm run build
npm run clean
npm run build
git diff --exit-code -- dist
git diff --check
```

Thay đổi script game phải chạy các regression liên quan, gồm `test:e2e:lua`
khi sửa real-Lua harness; thay đổi nghiệp vụ shop phải chạy test shop tương ứng.
Không gán nhãn nghiệm thu thiết bị thật từ Chrome mô phỏng.

## Kiểm tra builder Vercel tại local

Cần CLI Vercel đã đăng nhập và liên kết đúng project `tqs`. Hai lệnh đầu lấy
cấu hình và build local, không tạo deployment. File env tải về nằm trong
`.vercel/` bị Git bỏ qua; không in/chụp/sao chép các giá trị đó vào evidence.

```bash
vercel pull --yes --environment=production
vercel build --prod --yes
npm run verify:vercel
```

`verify:vercel` kiểm Build Output API v3, toàn bộ static byte-match
`dist-shop/`, và function cho mỗi endpoint `api/` (bỏ qua `_lib/`). Chạy ngay
sau build; khi source/config thay đổi phải build lại. Nó xác nhận artifact local,
chưa chứng minh builder hosted, API runtime hoặc đăng nhập production.
Tham chiếu chính thức: [vercel build](https://vercel.com/docs/cli/build) và
[cấu hình build/output](https://vercel.com/docs/builds/configure-a-build).

## Hai điểm phát hành

Push GitHub và deploy production đều là quyết định phát hành. Trước push phải
kiểm tra branch và liên kết auto-deploy của Vercel: push vào branch có tích hợp
có thể tự tạo deployment. Không giả định GitHub CI đã thành required gate.
Chỉ chọn đúng source/commit đã review; không gom tệp không liên quan vào commit.

Khi đợt phát hành đã được cho phép, dùng artifact Production vừa kiểm tra
(`vercel deploy --prebuilt --prod`) hoặc pipeline Git đã xác nhận. Ghi commit,
deployment ID, URL immutable, target, log builder và hash static. Không dùng
artifact cũ sau khi source/config thay đổi. Sau deploy phải kiểm tra HTTP root,
JS/CSS/SW, OAuth helper, API thiếu token `401`, CORS và so hash với artifact.
Nếu lỗi, ngừng promote và dùng bản READY trước đã biết tốt theo thao tác rollback
của Vercel; không build shop vào `dist/` để xử lý sự cố.

## Nghiệm thu thiết bị và trạng thái bằng chứng

Ghi theo từng bản phát hành, không kế thừa máy móc xác nhận của bản cũ:

| Hạng mục | Bằng chứng cần ghi | Trạng thái ngày 19/10/2026 của thay đổi build này |
| --- | --- | --- |
| Guard/build/clean | Lệnh, exit code, hash hai output game | LOCAL PASS, xem `CODEX_STATE.md` |
| TypeScript | Shop/API/tests, game app, game tools | LOCAL PASS |
| Vercel Production builder local | `vercel build --prod`, static và function | LOCAL PASS |
| Vercel hosted với `dist-shop/` | Deployment ID/URL, log builder, hash HTTP | OPEN, chưa tạo deployment mới |
| iPhone Safari và PWA | Model máy, iOS, mode, URL/deployment, ngày, người nghiệm thu | OPEN cho bản tiếp theo |
| Android Chrome | Model máy, OS/browser, URL/deployment, ngày, người nghiệm thu | OPEN cho bản tiếp theo |

Trên từng thiết bị thật: đăng nhập Google, quay lại app đúng phiên, tải lại/mở lại
PWA; với tài khoản được duyệt, vào phòng và chơi qua các tương tác liên quan;
xoay dọc/ngang, chạm hai ô ngựa, chọn/bỏ bài rồi Xác nhận/Hủy, cuộn nhiều kỹ năng.
Ghi PASS/FAIL từng scenario và lỗi quan sát được. Không lưu thông tin đăng nhập
hay token trong ảnh/log. Bản nghiệm thu chỉ đóng đúng thiết bị, bản build và
scenario đã thực hiện. Các gate native/official còn lại vẫn theo `CODEX_PLAN.md`.
