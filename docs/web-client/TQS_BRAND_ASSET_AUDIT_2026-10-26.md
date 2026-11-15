# Kiểm kê tài sản thiết kế — Tam Quốc Sát Mobile (26/10/2026)

Khảo sát repository `/Users/otada/Documents/GitHub/tqs`, game web tại `game/web/`, branch `main`. Phạm vi là game Quốc Chiến, không bao gồm TQSShop ở `src/`/`api/`.

## Kết luận triển khai

- Stack hiện tại: React 19, TypeScript 5.8, Vite 6, PWA standalone; Firebase/Google OAuth và cổng FreeKill. Không phát hiện dự án native Xcode/Android Gradle/Capacitor trong phạm vi được khảo sát.
- Flow: `App.tsx` chuyển `BootScreen` → `LoginScreen` → `LobbyScreen`/`WaitingRoomScreen` → `InitialGeneralPanel`/`GameBoardScreen` và `GameResultPanel`; thẻ bài/tướng qua `HandCardItem`, `GeneralChoiceCard`, hiệu ứng qua `CardVfxOverlay`.
- Hệ màu nhận diện mới: vàng `#D4AF37`, đen `#100E0C`, đỏ `#8B1E20`; toàn bộ nội dung chữ trong brand mới dùng tiếng Việt/Latin, không có ký tự Trung Quốc.
- Các file mới của game nằm trong `game/web/public/brand/`, với poster Lưu Bị cưỡi bạch mã theo ảnh người dùng cung cấp. Art này **chưa có hồ sơ giấy phép xuất bản**: xác minh quyền thương mại trước phát hành công khai. Logo SVG không chứa ảnh tham chiếu được cung cấp làm phương án thuần vector.

## Kiểm kê tài sản đang có

| Thư mục | Số file | Định dạng/dung lượng | Kích thước phổ biến |
|---|---:|---|---|
| `photo-assets/` | 1.693 | 1.577 JPG, 109 PNG, 7 WebP, 33,98 MiB | tướng 250×290/292 |
| `photo-assets/generals/` | 1.580 | 1.576 JPG, 4 WebP, 33,54 MiB | 250×290/292 |
| `photo-assets/equipIcon/` | 83 | PNG, 0,10 MiB | 28×22 |
| `photo-assets/back/` | 5 | PNG | 175×233 |
| `photo-assets/magatama/` | 9 | PNG | 26×26, 18×17 |
| `photo-assets/role/` | 4 | PNG | 43×47 |
| `photo-assets/death/` | 2 | PNG | 48×137, 115×188 |
| `card-catalog-art/` | 82 | PNG, 1,99 MiB | 93×130 |
| `anim/` | 135 | PNG, 5,28 MiB | 188×184, 240×240 |
| `audio/` | 97 | MP3, 2,46 MiB | — |
| `packages/` (public audio) | 40 | MP3, 0,76 MiB | — |

## Bảng asset và ưu tiên

Quy ước: **ĐÃ TẠO** = sản xuất và đặt vào project trong phiên này; **CÓ** = vốn có; **CÓ / CẬP NHẬT** = asset/flow hiện hữu đã gắn nhận diện mới; **THIẾU** = cần sản xuất nếu mở rộng phạm vi; P0 = ứng dụng/chức năng đang dùng, P1 = polish quan trọng, P2 = tương lai.

| Nhóm | Asset | Trạng thái | Mức | Quy cách |
|---|---|---|---|---|
| Nhận diện | Logo Chiến Ấn ngang (ảnh Lưu Bị) | ĐÃ TẠO | P0 | 1600×440 PNG trong suốt |
| Nhận diện | Logo Chiến Ấn ngang vector | ĐÃ TẠO | P1 | 1000×280 SVG |
| Nhận diện | Logo Chiến Ấn dọc có bạch mã | ĐÃ TẠO | P0 | 1024×1400 WebP |
| Nhận diện | Logo dọc SVG thuần vector | THIẾU | P2 | SVG tỷ lệ 3:4 |
| Nhận diện | Illustration Lưu Bị cưỡi bạch mã | ĐÃ TẠO | P0 | 900×1189 WebP |
| Nhận diện | Bảng màu/typography | ĐÃ TẠO | P0 | HEX + Be Vietnam Pro |
| PWA iOS | App icon master App Store | ĐÃ TẠO | P0 | 1024×1024 PNG RGB, không alpha |
| PWA iOS | Apple Touch Icon | ĐÃ TẠO | P0 | 180×180 PNG RGB |
| PWA Android | Launcher icon thường | ĐÃ TẠO | P0 | 192×192 PNG RGB |
| PWA Android | Launcher icon thường 512 | ĐÃ TẠO | P0 | 512×512 PNG RGB |
| PWA Android | Adaptive/maskable icon | ĐÃ TẠO | P0 | 512×512 PNG RGB |
| Web | Favicon | ĐÃ TẠO | P0 | 120×120 viewport SVG |
| Native iOS | AppIcon.appiconset | THIẾU | P2 | Asset catalog/Xcode |
| Native Android | mipmap density / adaptive foreground | THIẾU | P2 | mdpi đến xxxhdpi XML/PNG |
| Splash | Splash dọc marketing | ĐÃ TẠO | P1 | 1080×1920 WebP |
| Splash | Splash ngang marketing | ĐÃ TẠO | P1 | 1920×1080 WebP |
| Splash | Native launch storyboard/Android 12 SplashScreen | THIẾU | P2 | Storyboard/XML Android 12+ |
| Boot | Màn boot logo và loading progress | CÓ / CẬP NHẬT | P0 | React + CSS + PNG |
| Boot | Trạng thái tải lỗi và thử lại | CÓ | P0 | React/CSS responsive |
| Login | Header logo và key visual | CÓ / CẬP NHẬT | P0 | React + PNG/WebP |
| Login | Form xác thực/trạng thái access | CÓ | P0 | React/CSS |
| Login | Thiết kế hướng dẫn thêm ra màn hình chính | CÓ | P1 | HTML/CSS |
| Lobby | Nền sảnh/warroom | CÓ | P1 | WebP |
| Lobby | Logo mini cho thanh tiêu đề sảnh | THIẾU | P1 | SVG/PNG 240×72 |
| Lobby | Avatar người chơi và phòng | CÓ | P1 | React/CSS |
| Waiting Room | Thẻ ghế chờ, ready/status | CÓ | P0 | React/CSS |
| Game Board | Ảnh nền bàn chiến trường | CÓ | P0 | JPG/WebP |
| Game Board | HUD máu, lượt, tên, ghế | CÓ | P0 | React/CSS/PNG |
| Game Board | Vùng kỹ năng/nút kết thúc lượt | CÓ | P0 | React/CSS |
| Tướng | Chân dung tướng runtime | CÓ | P0 | 1580 JPG/WebP chủ yếu ~250×290/292 |
| Tướng | Portrait phiên bản Retina 2× | THIẾU | P2 | ~500×580 WebP/AVIF |
| Tướng | Thẻ chọn tướng chủ/phó | CÓ | P0 | React/CSS/JPG |
| Tướng | Khung thẻ nhân vật độc quyền brand | THIẾU | P2 | SVG hoặc nine-slice PNG |
| Phe | Phù hiệu mới Ngụy–Thục–Ngô–Quần | THIẾU | P1 | 4 SVG, 64×64 và 128×128 |
| Phe | Ảnh role dùng bởi runtime | CÓ | P0 | 4 PNG ~43×47 |
| Bài | Ảnh minh họa catalog | CÓ | P0 | 82 PNG 93×130 |
| Bài | Artwork bài runtime khác catalog | CÓ | P0 | PNG từ Vite/runtime packages |
| Bài | Mặt sau bài | CÓ | P0 | 5 PNG 175×233 |
| Bài | Khung lá bài / nhấn chọn / unavailable | CÓ | P0 | React/CSS/PNG |
| Bài | Mặt sau bài mang logo thương hiệu mới | THIẾU | P2 | ~350×466 WebP/PNG |
| Trang bị | Biểu tượng slot trang bị | CÓ | P0 | 83 PNG, chủ yếu 28×22 |
| Đồ họa UI | Bộ nút primary/secondary/disabled | CÓ | P0 | CSS + React |
| Đồ họa UI | Sprite icon menu/hỗ trợ/âm thanh | CÓ | P1 | Inline SVG |
| Đồ họa UI | Khung dialog, popup, tooltip | CÓ | P0 | CSS |
| Đồ họa UI | Bộ con dấu CTA riêng | THIẾU | P1 | SVG, 9-slice, 1×/2× |
| Hiệu ứng | Animation bài Slash/Jink và khác | CÓ | P0 | 135 PNG, nhóm 188×184 / 240×240 |
| Hiệu ứng | VFX vàng–đỏ riêng cho logo | THIẾU | P2 | WebP/PNG spritesheet hoặc CSS |
| Âm thanh | Nhạc nền/hiệu ứng | CÓ | P0 | 97 MP3 + 40 MP3 packages |
| Kết quả | Kết thúc ván thắng/thua | CÓ | P0 | React/CSS |
| Kết quả | Biểu trưng thắng/thua mới | THIẾU | P2 | 2 SVG 320×320 |
| Trạng thái | Empty, loading, error, offline, reconnect | CÓ | P0 | React/CSS |
| Trạng thái | Minh họa trạng thái đồng bộ brand | THIẾU | P2 | SVG/WebP 256×256 mỗi trạng thái |
| Cập nhật | Cảnh báo phiên bản và cập nhật PWA | CÓ | P0 | React/CSS + sw.js |
| Chia sẻ | Social OpenGraph/banner | THIẾU | P1 | 1200×630 PNG/JPG |
| Phân phối | Manifest PWA và metadata browser | CÓ / CẬP NHẬT | P0 | JSON/HTML |
| Phân phối | Phân phối Android/iOS native | THIẾU | P2 | APK/AAB/IPA |

### Vị trí và quyết định đối với từng asset

| Asset | File/vị trí | Xử lý |
|---|---|---|
| Logo Chiến Ấn ngang (ảnh Lưu Bị) | `game/web/public/brand/logo-horizontal.png` | Đã gắn vào boot và login |
| Logo Chiến Ấn ngang vector | `game/web/public/brand/logo-horizontal.svg` | Bản chỉ dùng chữ và biểu tượng, không mang ảnh gốc |
| Logo Chiến Ấn dọc có bạch mã | `game/web/public/brand/logo-vertical.webp` | Truyền thông và nội dung dọc |
| Logo dọc SVG thuần vector | `brand (đề xuất)` | Chưa có bản dọc vector tách biệt |
| Illustration Lưu Bị cưỡi bạch mã | `game/web/public/brand/liu-bei-white-horse.webp` | Từ hình người dùng đã cung cấp; cần xác nhận quyền sử dụng trước phát hành |
| Bảng màu/typography | `brand SVG, styles.css, index.html` | Vàng #D4AF37, đen #100E0C, đỏ #8B1E20 |
| App icon master App Store | `game/web/public/brand/icon-master-1024.png` | Dùng master khi có wrapper native |
| Apple Touch Icon | `game/web/public/apple-touch-icon.png` | Đang dùng trong index.html |
| Launcher icon thường | `game/web/public/icon-192.png` | Đang khai báo manifest |
| Launcher icon thường 512 | `game/web/public/icon-512.png` | Đang khai báo manifest |
| Adaptive/maskable icon | `game/web/public/brand/icon-maskable-512.png` | Đang khai báo purpose=maskable |
| Favicon | `game/web/public/favicon.svg` | Biểu tượng con dấu TQS mới |
| AppIcon.appiconset | `Chưa có dự án iOS native` | Chỉ cần khi thêm wrapper Xcode/Capacitor |
| mipmap density / adaptive foreground | `Chưa có dự án Android native` | Chỉ cần khi thêm wrapper Android |
| Splash dọc marketing | `game/web/public/brand/splash-portrait.webp` | Tài nguyên thiết kế; PWA dùng boot screen thực tế |
| Splash ngang marketing | `game/web/public/brand/splash-landscape.webp` | Tài nguyên thiết kế; chưa có native launch screen |
| Native launch storyboard/Android 12 SplashScreen | `Chưa có shell native` | Không áp dụng cho PWA hiện tại |
| Màn boot logo và loading progress | `game/web/src/BootScreen.tsx` | Đã gắn logo mới, giữ progress, error và tip |
| Trạng thái tải lỗi và thử lại | `BootScreen.tsx` | Giữ chức năng đang hoạt động |
| Header logo và key visual | `LoginScreen.tsx, HeroSpotlight.tsx` | Giữ Google OAuth, thêm hero Lưu Bị dạng quảng bá |
| Form xác thực/trạng thái access | `LoginScreen.tsx` | Giữ pending, suspended, loading, error |
| Thiết kế hướng dẫn thêm ra màn hình chính | `LoginScreen.tsx` | Có sẵn iPhone/Android |
| Nền sảnh/warroom | `game/web/public/photo-assets/bg-warroom.webp` | Đang dùng; xem xét phối màu sau nghiệm thu |
| Logo mini cho thanh tiêu đề sảnh | `LobbyScreen.tsx (đề xuất)` | Chưa tích hợp biến thể nhận diện vào thanh sảnh |
| Avatar người chơi và phòng | `LobbyScreen.tsx` | Bảo toàn avatar, dữ liệu phòng |
| Thẻ ghế chờ, ready/status | `WaitingRoomScreen trong LobbyScreen.tsx` | Có trạng thái hệ thống đang dùng |
| Ảnh nền bàn chiến trường | `photo-assets/gamebg-upstream.jpg, bg-battlefield.webp` | Giữ upstream để không phá layout đang ổn |
| HUD máu, lượt, tên, ghế | `GameBoardScreen.tsx, photo-assets/magatama/` | Không thay logic hoặc tiết lộ tướng ẩn |
| Vùng kỹ năng/nút kết thúc lượt | `GameplayControls.tsx` | Có các trạng thái thực thi |
| Chân dung tướng runtime | `photo-assets/generals/` | Không thay định danh hoặc tên tướng gameplay |
| Portrait phiên bản Retina 2× | `photo-assets/generals/ (đề xuất)` | Chỉ làm nếu có nguồn được cấp phép |
| Thẻ chọn tướng chủ/phó | `GeneralChoiceCard.tsx, InitialGeneralPanel.tsx` | Giữ che giấu tướng theo luật |
| Khung thẻ nhân vật độc quyền brand | `brand/ui (đề xuất)` | Không cần ngay cho chức năng Quốc Chiến |
| Phù hiệu mới Ngụy–Thục–Ngô–Quần | `brand/factions (đề xuất)` | Tạo vector riêng, có chữ Việt nếu dùng chữ |
| Ảnh role dùng bởi runtime | `photo-assets/role/` | Giữ nguyên dữ liệu và nghĩa của game |
| Ảnh minh họa catalog | `card-catalog-art/` | Hiện diện; giữ ảnh upstream |
| Artwork bài runtime khác catalog | `game/web/vite.config.ts + runtime/packages` | Được phát qua dist/packages theo cơ chế đang có |
| Mặt sau bài | `photo-assets/back/` | Bảo toàn tình trạng bài kín |
| Khung lá bài / nhấn chọn / unavailable | `HandCardItem.tsx và styles.css` | Trạng thái tương tác có sẵn |
| Mặt sau bài mang logo thương hiệu mới | `brand/cards (đề xuất)` | Chỉ thay khi kiểm thử privacy/render |
| Biểu tượng slot trang bị | `photo-assets/equipIcon/` | Có sẵn, cần giữ mapping |
| Bộ nút primary/secondary/disabled | `styles.css, GameplayControls.tsx` | Tô màu brand có thể làm P1 |
| Sprite icon menu/hỗ trợ/âm thanh | `BootScreen.tsx, LoginScreen.tsx` | Đã có vector đơn giản |
| Khung dialog, popup, tooltip | `styles.css, UI components` | Không ảnh hưởng tiến trình game |
| Bộ con dấu CTA riêng | `brand/ui (đề xuất)` | Thiết kế từ master mới |
| Animation bài Slash/Jink và khác | `anim/ + CardVfxOverlay.tsx` | Giữ hoạt họa đã dùng trong gameplay |
| VFX vàng–đỏ riêng cho logo | `brand/vfx (đề xuất)` | Không ưu tiên hơn logic game |
| Nhạc nền/hiệu ứng | `audio/ và packages/` | Kiểm thử quyền âm thanh trước phát hành |
| Kết thúc ván thắng/thua | `GameResultPanel.tsx` | Giữ xử lý GameOver |
| Biểu trưng thắng/thua mới | `brand/states (đề xuất)` | Thiết kế khi làm polish end game |
| Empty, loading, error, offline, reconnect | `BootScreen.tsx, LoginScreen.tsx, StatusFooter.tsx, App.tsx` | Không loại bỏ trạng thái đang dùng |
| Minh họa trạng thái đồng bộ brand | `brand/states (đề xuất)` | Ưu tiên sau responsive và core |
| Cảnh báo phiên bản và cập nhật PWA | `ForceUpdateGuard.tsx, build-service-worker.mjs` | Worker đóng gói hash, không cache gateway |
| Social OpenGraph/banner | `brand/social (đề xuất)` | Cho trang giới thiệu bên ngoài game |
| Manifest PWA và metadata browser | `manifest.webmanifest, index.html` | Đã cập nhật màu, icon và maskable |
| Phân phối Android/iOS native | `Không phát hiện dự án native` | PWA cài từ trình duyệt, không có build native |

## Cơ chế đóng gói và yêu cầu kích thước

- `game/web/public/` được Vite đưa vào `game/web/dist/` cùng các file ở `game/web/src/` và asset runtime do `game/web/vite.config.ts` phát sinh. Đích release từ `deploy/mobile/package-release.mjs` lấy dist và runtime pin, tạo kiểm kê SHA-256.
- `game/web/scripts/build-service-worker.mjs` ghi hash app shell cho SVG/PNG/HTML/JS/CSS/WASM/manifest và riêng WebP dưới `brand/`. Không quét toàn bộ chân dung tướng WebP để tránh tải thừa; không cache token, giao dịch private hoặc gateway.
- Manifest PWA dùng PNG 192/512 (`any`), 512 `maskable`, Apple Touch 180; master 1024 RGB để phục vụ store/native tương lai. Browser-controlled PWA splash dùng manifest và màn Boot hiện có; WebP splash dọc/ngang là thiết kế cung cấp để dùng về sau, chưa là launch storyboard native.
- Responsive cần nghiệm thu tối thiểu 320×568, 360×800, 390×844, 412×915, 768×1024, 844×390; chú ý safe area và trạng thái form OAuth. Chân dung và bài kín chỉ dùng asset runtime được backend cho phép hiển thị.

## File mới/sửa trong phiên

- **Sửa**: `game/web/public/icon-192.png`, `icon-512.png`, `apple-touch-icon.png`, `favicon.svg`, `manifest.webmanifest`, `game/web/index.html`.
- **Sửa**: `game/web/src/BootScreen.tsx`, `LoginScreen.tsx`, `HeroSpotlight.tsx`, `styles.css`; `game/web/scripts/build-service-worker.mjs`.
- **Tạo**: thư mục `game/web/public/brand/` với logo ngang SVG/PNG, logo dọc WebP, art Lưu Bị WebP, splash dọc/ngang WebP, icon maskable và master 1024; `game/web/scripts/generate-brand-assets.py` (Pillow, yêu cầu source do người có quyền sở hữu cung cấp).
- **Không chỉnh sửa**: dữ liệu cặp tướng chủ/phó, rule Lua/C++, TQSShop, production, những thay đổi đang dở trong docs khác.

## Kiểm tra

- **PASS** `npm --prefix game/web run build`: audit game, `tsc --noEmit`, Vite, service worker tạo **532 file shell** theo SHA-256, build ID `5a584ec86f8a…`. Vite cảnh báo chunk JS lớn hơn 500 KiB (cảnh báo tối ưu hiệu năng, không phải lỗi build).
- **PASS 21/21** `npm --prefix game/web run test:card-display`: card display/portrait privacy và các contract liên quan.
- **PASS 5/5** `npm --prefix game/web run test:release`: release hashing, QA package filtering, dirty checkout safety.
- **PASS** `npm --prefix game/web run test:e2e:pwa`: Chrome thật ở môi trường local, cập nhật same-build/genuine-build, offline app shell, IndexedDB và private gateway cache.
- **PASS** kiểm tra responsive Chrome: `320×568`, `390×844`, `768×1024`, `844×390`; logo tải được, nằm trong viewport, không tràn ngang; riêng landscape dùng logo thu nhỏ ở góc trên trái.
- **PASS** `git diff --check`, manifest paths/độ phân giải icon/mode RGB, parser SVG, decode tất cả ảnh brand.
- **Giới hạn QA**: chỉ kiểm tra Boot ở môi trường preview không có gateway; chưa kiểm thử Login OAuth thực/thiết bị vật lý. Chưa có triển khai production hay push. Quyền phát hành ảnh tham chiếu và upstream vẫn cần xác minh.
