# TQSVN / Quốc Chiến — kế hoạch hoàn thiện popup chọn chủ tướng, phó tướng

**Ngày lập:** 23/10/2026<br>
**Trạng thái:** ĐANG TRIỂN KHAI — G0–G4 bounded hoàn tất; G5 mở<br>
**Phạm vi:** `game/web` cho `new_heg_mode`, từ `CustomDialog` chọn tướng đến reply Lua hợp lệ; kiểm tra hệ quả trong trận.<br>
**Ngoài phạm vi:** tướng/skill không phục vụ Quốc Chiến, các mode khác, thay pin upstream, hệ thống tài khoản, gateway/native production, TQSShop, tự phát hành.<br>
**Nguyên tắc:** C++/Lua của snapshot đang ghim quyết định luật; QML cùng snapshot quyết định hành vi/gợi ý hiển thị; web có thể bố trí khác để phù hợp di động.

## 0. Quyết định và điều kiện nghiệm thu tổng thể

1. Người chơi thấy **chính xác danh sách tướng được cấp trong request của mình**, thứ tự do server đưa; chọn hai ID **có thứ tự** (`main`, `deputy`). Không lấy danh sách tướng toàn cục hay nhìn dữ liệu kín của người khác.
2. Tính hợp lệ và danh sách thế lực phải xuất phát từ Lua: `Fk:canMatchInHegemony` **và** `Fk:getKingdomInHegemony`, thông qua cầu nối read-only hiện có `__web_general_kingdoms`. Frontend chỉ lưu trạng thái thao tác; không sao chép luật bằng TypeScript.
3. Mỗi request gửi **tối đa một phản hồi do người dùng xác nhận** theo đúng cặp `["main,deputy", "kingdom,k"]`; không sửa tính năng kiểm bytes CBOR, request ID, expiry, quyền gửi reply ở `GameConnection`.
4. Hết giờ để **server** thực hiện default/fallback. Client không tự gửi cặp ngẫu nhiên, không gửi khi request cũ/hết hạn và không hiển thị đã xác nhận nếu chưa chuyển được reply.
5. Dùng thẻ tướng có ảnh, hai vị trí chủ/phó, nhãn thế lực, thông tin tùy thuộc metadata đã xác minh, nút xem kỹ năng và tiến trình đếm ngược. Ảnh thiếu phải có fallback không làm hỏng bố cục.
6. Từ 320px portrait đến landscape và desktop, xem/chọn/xác nhận được bằng chạm, chuột và bàn phím; nội dung có thể cuộn nhưng CTA không bị che, quản lý focus trong modal đúng.
7. Test cấp logic, browser + Lua thật, native QA, reconnect/privacy đều có bằng chứng tương ứng trước khi công bố hoàn thành. Hosted là gate riêng; không quy đổi local PASS thành production PASS.

**Definition of Done cuối:** tất cả ticket `SEL-00..SEL-20` thuộc đợt cốt lõi đạt tiêu chí cụ thể; không còn lỗi chặn chọn cặp hợp lệ/không thể xác nhận trong các viewport mobile đã kiểm thử; native nhận đúng chủ/phó/thế lực và che tướng sau chọn; các suite phạm vi liên quan PASS trên checkout ứng viên; có evidence hosted và release review độc lập trước khi release/sign-off. Nghiệm thu iPhone/Android vật lý đã được người dùng bỏ khỏi phạm vi của plan này; không ghi nhận là PASS và cũng không còn là điều kiện chặn G5. Các tính năng optional `SEL-X*` không chặn core.

## 1. Cơ sở mã nguồn và phát hiện đã xác minh

| Trục | File/đoạn kiểm tra | Hành vi / ràng buộc |
| --- | --- | --- |
| Server Hegemony | `runtime/packages/hegemony/pkg/gamemodes/new_hegemony_mode.lua:200-261` | `generalNum >= 5`, phân phát `#players * generalNum`, request chọn hai tướng; ghi `__heg_general`, `__heg_deputy`, `__heg_kingdom`, rồi che bằng `anjiang`. |
| Server dialog | `runtime/packages/freekill-core/ltk/server/room.lua:1320-1470` | QML `ChooseInitialGeneralBox` + model; `choiceNum=2`, `enabledKingdoms`, `generalTimeout`, default pair; server đọc chuỗi `"main,deputy"`/`"kingdom,k"`. |
| Luật | `runtime/packages/freekill-core/ltk/core/engine.lua:600-648` | `canMatchInHegemony` và `getKingdomInHegemony` **không đồng nhất**: trường hợp Wild và enabled/subkingdom đòi hỏi cả hai phép kiểm. |
| Native model | `runtime/packages/freekill-core/LunarLtk/Models/Popups/ChooseInitialGeneralModel.qml:39-60,62-103` | Filter tướng thứ hai theo engine; nhấn tướng đang chọn thì bỏ khỏi danh sách (vị trí sau được dồn lên); khi đủ 2 không chọn thêm tướng thứ ba; đánh dấu vị trí/companion. |
| Native view | `runtime/packages/freekill-core/LunarLtk/Pages/Popups/ChooseInitialGeneralBox.qml:45-159,183-509,512-552` | Danh sách thẻ hình, 2 slot, icon kingdom, nút OK/detail, progress, optional convert/free-assign. |
| Web UI | `game/web/src/InitialGeneralPanel.tsx:17-112` | Nút tướng chỉ có chữ, có skill inspector/radio kingdom/timer; nhấn chủ khi có 2 làm rỗng cả cặp, nhấn tướng thứ ba bắt đầu lại; không có thẻ hình/companion/HP. |
| Web validator | `game/web/src/engine/generalSelection.ts:13-33`; `connection.ts:348-399`; `hostLua.ts:965-974,1100-1117` | Nhận `CustomDialog` chuyên biệt; Lua đọc danh sách kingdom; phản hồi user-confirmed có requestId, expiry, CBOR byte-check. |
| Web layout | `game/web/src/styles.css:60-70,124-148,8342-8359`; `game/web/src/RequestDialog.tsx` | Request panel hiện fixed width 520px; có RequestDialog dùng chung cho focus trap/portal, nhưng popup chọn tướng chưa dùng shell đó. |
| Art & skill | `game/web/src/generalArt.ts`, `PlayerPhotoPanel.tsx`, `SkillInfo.tsx`; `public/photo-assets/generals` | Có helper ảnh exact-name/base-name và fallback; 1.580 file ảnh tướng được quan sát ở local (chưa kiểm đủ theo pool hiện hành). Skill inspector đọc Lua, không gửi gameplay reply. |

**Kiểm tra provenance ngày 23/10:** SHA-256 model QML ở `scratch/upstream` và `runtime` đều `f7e06a86702426cf24139d8acaf2001399e176c4a8618b2f1d89f4e0c6526074`; view QML đều `c6c24a917607a0851ba793622a1999a684b12da15c836ee566095016aca2e69a`. Hai file này byte-identical ở checkout khảo sát; vẫn phải kiểm pin trong `deploy/freekill-native/versions.env` và `game/web/scripts/upstream-packages.ts` trước triển khai/QA. **Không** suy rộng hash QML sang toàn bộ runtime/FreeKill.

### 1.1. Những khác biệt logic phải giải quyết trước UI

| Trạng thái | QML gốc quan sát | TQSVN hiện tại | Quyết định triển khai |
| --- | --- | --- | --- |
| Chưa chọn | Cho chọn bất kỳ tướng được cấp | Tương đương | Giữ; hiển thị fallback nếu chưa có cặp hợp lệ. |
| Đã chọn chủ A | Chỉ B với `generalFilter` hợp lệ được bấm; A có thể bỏ | B không hợp lệ vẫn bấm, báo warning | Tính trạng thái tương thích qua Lua, disabled + giải thích; vẫn test guard khi gọi trực tiếp. |
| Đã chọn [A,B], bấm C | C **không selectable** trong UI do `generalFilter` false; phải bỏ chọn trước | Xóa cả cặp thành [C] | Khóa C khi đủ cặp; hướng dẫn bỏ chọn vị trí trước. |
| Đã chọn [A,B], bấm A | `splice` A; B trở thành chủ | Xóa hết | Theo native: còn [B]; tính lại lựa chọn hợp lệ. |
| Đã chọn [A,B], bấm B | Còn [A] | Còn [A] | Giữ. |
| Một/hai thế lực | QML chỉ bắt chọn khi >1; display tự suy ra nếu 1 | Radio khi >1, text nếu 1 | Cho 1 thì auto-select **trong trạng thái UI**, >1 phải chọn thủ công, đổi cặp phải vô hiệu hóa lựa chọn cũ. |
| Wild/châu liên bích hợp/HP | QML lấy `Fk/Ltk` registry + model | Chưa có đủ metadata | Làm hợp đồng metadata read-only trước; hiển thị theo sự thật của snapshot. |
| Hết giờ | Server có default pair; QML progress | UI hết giờ chặn nút | Hiển thị trạng thái chờ server, chặn hành động cũ; không giả lập default. |

**Lưu ý luật:** `Fk:canMatchInHegemony(wildMain, deputy)` có thể true ngay cả khi không có kingdom hợp lệ sau lọc `enabledKingdoms`. Cần dùng kết quả cuối của `__web_general_kingdoms` mới bật nút và CTA. Kết quả `getKingdomInHegemony` có thể bị xoá toàn bộ khi một lựa chọn kingdom không thuộc enabled (theo mã gốc), nên không tự lọc mảng phía frontend rồi kết luận hợp lệ.

## 2. Luồng tương tác mục tiêu

**Máy trạng thái UI:** `waiting` → `select-main` → `select-deputy` → `select-kingdom` (chỉ nếu >1) → `ready` → `submitting` → `done`; nhánh `expired`, `request-replaced`, `disconnected` đều loại bỏ thao tác của request cũ. `waiting` chỉ là trạng thái component khởi tạo khi request đã đến, không phải trạng thái gửi mạng.

1. Nhận `CustomDialog` đã parse; remount theo `(requestId, receivedAt)`. Lấy labels và metadata hiển thị đúng offered IDs, không lấy theo toàn bộ engine registry.
2. Ban đầu card nào thuộc offer cũng có thể chọn làm chủ. Sau chọn A, hỏi Lua cho các phương án `(A,B)` còn lại, lưu kết quả theo request + A để tránh gọi Lua trong render; hiển thị disabled đối với B không hợp lệ.
3. Khi chọn B hợp lệ, lấy kingdom list từ cùng read-only Lua call. Nếu có đúng một kingdom, tự dùng kingdom đó; nếu có nhiều, chọn bằng button/radio có accessible name; nếu rỗng, hiển thị lỗi và giữ khả năng bỏ chọn.
4. Bấm card A đang chọn: bỏ A, B chuyển thành chủ; tái tính valid deputies, huỷ lựa chọn kingdom cũ. Bấm card B: giữ A. Bấm C sau khi đủ cặp: không thay trạng thái; người dùng chủ động bỏ chọn trước. Nút `Chọn lại` đưa về trạng thái rỗng.
5. Bấm `Xác nhận` khi ready: duy nhất `adapter.chooseInitialGenerals(requestId,A,B,k)`; disable thao tác trong lúc busy; lỗi nhận về chỉ hiển thị ở UI của request hợp lệ. Không tự gọi reply khi chọn card, mở skill info hoặc hết giờ.
6. Khi request hết hạn/đã bị thay/bị ngắt kết nối: gỡ lựa chọn, đóng sheet thông tin nếu cần, chặn callback cũ; UI không giữ thông tin offer private quá vòng đời request.

### 2.1. Trạng thái từng thẻ

`normal` / `main-selected` / `deputy-selected` / `invalid-for-deputy` / `locked-pair-full` / `expired` / `busy`. Disabled phân biệt bằng màu **và** nhãn/hint; skill inspector vẫn đọc được thông tin đã công khai trong offer khi thao tác chọn bị disabled. Trên desktop dùng tooltip/hover bổ trợ; mobile hiển thị nguyên nhân qua nút info/description dùng được bằng chạm. Thẻ bấm và nút xem kỹ năng là hai điều khiển riêng, không gắn `onClick` chồng nhau.

### 2.2. Phác thảo bố cục chức năng

**Desktop ≥900px:** modal max-width tính theo viewport (không cố định 520px); vùng trái là grid thẻ 3–6 cột tùy số offer và kích thước; vùng phải gồm slot chủ/phó với hình thu nhỏ, kingdom picker, trạng thái chọn; footer cố định trong modal gồm đếm ngược/progress + nút `Chọn lại` và `Xác nhận`. Chỉ grid ảnh cuộn, giữ header/footer nhìn thấy. Không che board/tăng kích thước board.

**Portrait 320–430px:** bottom sheet `max-height ≤ 100dvh - safe areas`, header 1–2 dòng; grid tối thiểu 2 cột; hai ô đã chọn ở vùng tóm tắt gọn; kingdom và CTA sát đáy trong phần không cuộn; chỉ danh sách card cuộn, scroll containment tránh cuộn trang/bàn chơi; mọi nút có vùng chạm hợp lý ≥44×44 CSS px nơi khả thi (icon info có touch-area bao ngoài).

**Landscape thấp 360–520px:** modal giữa màn hình có giới hạn chiều cao `dvh`; ưu tiên 2 vùng song song khi đủ chiều rộng; header/footer thu gọn, có inner scroll cho grid; không để footer hoặc nút thông tin phủ nút xác nhận. Hỗ trợ resize/rotate khi đang chọn mà không mất trạng thái hợp lệ.

## 3. Backlog thi công theo dependency, ưu tiên và mức độ

Ưu tiên `P0` là điều kiện an toàn và đúng luật, `P1` là parity trực quan, `P2` là mobile/a11y, `P3` là nghiệm thu mở rộng. Độ phức tạp tương đối `S/M/L` để chia commit nhỏ; **không** phải lịch hứa hẹn.

| ID | Ưu tiên | Độ khó | Việc giao được | Phụ thuộc | Tiêu chí nghiệm thu tại ticket |
| --- | --- | --- | --- | --- | --- |
| SEL-00 | P0 | S | Chụp baseline/pin/contract và catalog offer | — | So SHA/pin chính xác, ghi số tướng offer thực tế + enabled kingdoms + file test hiện hữu; không dump private values. |
| SEL-01 | P0 | M | Tách logic state-machine thành hàm thuần `initialGeneralChoice.ts` hoặc tương đương | 00 | Test chuyển trạng thái đủ 0/1/2 chọn, bỏ A/B, reset, không cho chọn C khi đủ cặp. |
| SEL-02 | P0 | M | Tính allowed deputy và kingdom theo Lua với cache theo `requestId/main/deputy` | 01 | Không gọi Lua trong JSX render cho hàng loạt card; cache bị vô hiệu khi request đổi; trường hợp Wild/subkingdom trả đúng oracle. |
| SEL-03 | P0 | S | Hành vi chọn thế lực 0/1/N, làm mới khi cặp đổi | 01–02 | Nút xác nhận chỉ bật với `kingdom` thuộc danh sách Lua hiện thời, đổi A/B không giữ thế lực cũ. |
| SEL-04 | P0 | M | Điều kiện expired/busy/replaced/reconnect, trạng thái chờ fallback | 01–03 | Không gửi reply tự động; thử requestId cũ/hết hạn/disconnect không sinh frame; timeout UI không treo ở `đang gửi`. |
| SEL-05 | P0 | S | Không đổi protocol; rà adapter/CBOR safety + test chống double-confirm | 02–04 | Reply byte-exact `['A,B','kingdom,k']`; chỉ 1 frame, source của user action xác định; sai request/kingdom bị chặn. |
| SEL-06 | P0 | M | Gắn `RequestDialog` cho chọn tướng, chỉnh focus/cancel policy | 04 | `role=dialog`, `aria-modal`, focus vào phần tử phù hợp, Tab trap, Escape không gửi cancel cho yêu cầu bắt buộc; modal không bị clipping/z-index. |
| SEL-07 | P1 | M | API Lua metadata **read-only và bounded** cho offered generals | 00 | Trả `name`, kingdom/subkingdom, main/deputy HP adjustment, companion metadata nếu engine có; chỉ ID offer, không lộ private oppo; fallback khi trường thiếu. |
| SEL-08 | P1 | M | Component thẻ tướng có art/fallback, vai trò, trạng thái | 01–02,07 | Art exact/base safe, 404 không bắn tràn lan, tên readable/tooltip, màu và text khi selected/invalid; ảnh tỉ lệ đúng. |
| SEL-09 | P1 | S | Hai slot chủ/phó có ảnh + thông tin chung và đổi trạng thái | 08 | Cặp hiển thị đúng thứ tự trong cả grid và slot; bỏ A làm B chuyển chủ; không có ảnh nhầm ID. |
| SEL-10 | P1 | M | Kingdom chips/badge theo metadata đúng, có nhánh thiếu icon | 03,07–09 | 1 kingdom xác định rõ, nhiều kingdom bắt chọn; Wild/Jin/không có ảnh không hiện cờ sai; không hardcode bốn kingdom. |
| SEL-11 | P1 | M | HP điều chỉnh main/deputy và biểu tượng companion/Châu liên bích hợp | 07–09 | Giá trị đọc registry đúng vị trí, companion predicate theo source, không tự tính HP cuối theo công thức đoán; thiếu metadata thì ẩn field có kiểm soát. |
| SEL-12 | P1 | S | Skill info hoạt động độc lập với chọn tướng; labels Việt | 08 | Nhấn xem kỹ năng không chọn/huỷ tướng, không gửi Lua reply, mở/đóng info ở tất cả viewport. |
| SEL-13 | P1 | S | Progress bar đồng bộ `receivedAt`/`expiresAt` và request deadline | 04,06 | Thanh tiến trình monotonic, không âm/NaN, `timeout=null` ẩn progress; giảm motion nếu cần; sau 0 khóa CTA và chờ server. |
| SEL-14 | P2 | M | Desktop layout linh hoạt, grid-scroll/footer cố định | 06,08–13 | 5/7/10 và ≥16 offer hiển thị không overflow; card/slot/CTA không che nhau tại 1280×800, 1440×900. |
| SEL-15 | P2 | L | Portrait 320/360/390/412/430, safe-area, touch targets | 14 | Nút OK luôn chạm được; card đầu/cuối xem được, không scroll body dưới dialog; không có scroll x; test keyboard ảo nếu xuất hiện. |
| SEL-16 | P2 | M | Landscape 667×375, 844×390, 932×430; orientation/zoom | 15 | Rotate giữ cặp và kingdom; grid/CTA không bị crop; landscape thấp vẫn thao tác đầy đủ. |
| SEL-17 | P2 | M | Accessibility/localization/perf | 06,08–16 | Screen reader đọc vị trí, unavailable reason, countdown vừa đủ; Tab/Shift+Tab/Enter/Space; 50+ cards không gây giật timer; text dài không phá grid. |
| SEL-18 | P3 | M | Unit + browser E2E tất cả transition | 01–17 | Unit contract full matrix PASS, browser 5/7/10/16+ cards/empty art/long names, inspector, keyboard, timeout, request replacement. |
| SEL-19 | P3 | L | Real Lua và native QA tích hợp, reconnect/privacy | 18 | Lua oracle và CBOR PASS; native chọn→ẩn→vào lượt→GameOver trong room QA; reconnect không lộ tướng và không double reply. |
| SEL-20 | P3 | M | Hosted gameplay evidence, release-review/rollback riêng | 19 | Hosted OAuth → lobby → phòng → valid pair/confirm → GameOver → logout/relogin và desktop interaction PASS; candidate/hosted phân biệt; có gate release độc lập trước deploy. Nghiệm thu thiết bị vật lý không thuộc scope. |

**Optional (không chặn cốt lõi):** `SEL-X1` đổi cùng tên (`SameConvert`), `SEL-X2` free-assign, `SEL-X3` ảnh/animation cao cấp. Chỉ mở khi khảo sát settings `disableSameConvert`, `enableFreeAssign`, mô hình Lua, asset có quyền sử dụng và các đường dẫn hợp lệ. Không bổ sung chức năng thay tướng nếu native/room không cho phép.

### 3.1. File dự kiến sửa và chủ đích

| File | Dự kiến | Ranh giới |
| --- | --- | --- |
| `game/web/src/InitialGeneralPanel.tsx` | Tổ chức lại UI, giữ state/gọi adapter đúng lifecycle | Không tự tính match/kingdom từ text. |
| `game/web/src/engine/initialGeneralChoice.ts` **(mới, tên đề xuất)** | Reducer/state-machine thuần, helper derived state | Không import socket, không gửi reply. |
| `game/web/src/GeneralChoiceCard.tsx` **(mới, tên đề xuất)** | Thẻ artwork, icon, state, info button | Chỉ hiển thị data offer/metadata được cấp. |
| `game/web/src/engine/gameAdapter.ts` | Đầu đọc Lua metadata public-to-user nếu cần | Không đổi send method hoặc auth. |
| `game/web/src/engine/hostLua.ts` | Hàm read-only metadata giới hạn theo offer nếu registry web còn thiếu | Không xuất player marks/hidden hands/secret generals. |
| `game/web/src/engine/connection.ts` | Nếu bắt buộc, cache helper được khóa theo pending request | Giữ nguyên `respondToInitialGeneral` bytes và authorization. |
| `game/web/src/generalArt.ts`, `SkillInfo.tsx` | Tái dùng helpers/art/inspector; sửa tối thiểu | Không quét speculative asset path; không làm info phát action. |
| `game/web/src/RequestDialog.tsx`, `App.tsx` | Gắn đúng modal lifecycle; chỉ điều chỉnh shell nếu thật sự cần | Không áp thay đổi phá dialog khác. |
| `game/web/src/styles.css` | CSS namespaced `sg-initial-*`, desktop/mobile/landscape; safe area | Tránh override global phá board/Shop. |
| `game/web/scripts/initial-general-choice.test.ts` **(mới)** | Reducer, Lua validation contract, expiry & state | Không test tự khẳng định logic TS sai luật. |
| `game/web/scripts/connection.test.ts`, `smoke.ts`, `real-lua-e2e/run.ts`, `browser-e2e/run.ts` | Test request-gate, Lua parity, layout + inspector | Giữ selector ổn định qua `data-testid`/ARIA; không gom cả `button` trong entry. |

## 4. Ma trận bắt buộc cho unit, UI và Lua/native

| Nhóm | Kịch bản tối thiểu | Oracle / điều kiện PASS |
| --- | --- | --- |
| Offer | 5, 7, 10, 16, nhiều hơn một viewport; order không trùng; payload thiếu/giả mạo | `parseInitialGeneralPrompt` chỉ nhận đúng schema; thứ tự card khớp offer, không crash. |
| Selection | Chọn A; chọn B đúng; chọn B sai; bấm lại A/B; bấm C khi 2 đã đầy; Reset; nhấn nhanh 2 lần | State khớp bảng 1.1, không có reply trước confirm. |
| Kingdom | 0 / 1 / ≥2 quốc gia; chọn k rồi đổi cặp; kingdom không enabled | Mảng thế lực phải trùng `__web_general_kingdoms`; CTA chỉ ready khi hợp lệ. |
| Engine edge | Standard, Wild-main, Wild-deputy, subkingdom, multi-kingdom, same-ID, enabled subset, ngoại lệ `mouxusheng` | So **thực tế** `canMatch` + `getKingdom`, không JS mô phỏng; unknown scenario ghi blocked/unsupported. |
| Time | timeout null, thời gian còn ít, 0, time jump/background/foreground | Không tự reply; tránh gửi request cũ, không progress âm. |
| Race | confirm ngay sát deadline, connection lost, CancelRequest, request thay ID, thông báo lỗi Lua | Không double frame; lỗi hiện đúng request mới; không rò stale selection. |
| Wire | happy path `['ld__bianfuren,m_heg__dianwei','kingdom,wei']`, byte-exact CBOR | Local `connection.test` + real Lua E2E đều xác minh; không phát dữ liệu khi mở info. |
| Privacy | 2 người chơi chọn 2 cặp khác nhau; spectator/reconnect; hidden `anjiang` | Chỉ self thấy offer, không rò opponent marks, log/evidence không ghi raw general/card IDs. |
| Images | Tướng có art exact; có base art; không art; load fail; kingdom không có png | Placeholder ổn định, không hàng loạt 404, nhãn luôn đọc được. |
| Metadata | main/deputy HP khác nhau, companion có/không, double kingdom, Wild | Icon/chỉ số hiện chính xác theo registry, không hiển thị số suy đoán. |
| Layout | 320×568, 360×667, 390×844, 412×915, 430×932, 667×375, 844×390, 932×430, 1280×800, 1440×900 | CTA, info, hai slot đều thấy/click; không clipping/overlap/scroll x; chiều cao ảnh đúng. |
| Input | Touch, mouse, keyboard, screenreader; click info khi card invalid | Mỗi thao tác có phản hồi đúng, focus không thoát modal, không chọn nhầm tướng. |
| Native flow | Auth QA→room `new_heg_mode`→offer→confirm→ẩn tướng→đánh một lượt→GameOver→reconnect | Server nhận đúng cặp, đúng `__heg_*` trong phạm vi QA có thẩm quyền; người khác không thấy; QA cleanup, không đụng production. |

**Fixture chuẩn:** các unit có thể fake hợp đồng ở tầng transport; gate luật phải gọi **Lua registry thực** của snapshot đang ghim. `__web_general_kingdoms` đã dùng cả `canMatch` và `getKingdom`; test thêm trường hợp khi kết quả hai phép này khác nhau. QA evidence chỉ lưu counts, boolean, viewport, request class, command/status, hash/commit/pin, không lưu raw offer, ID private hoặc frame CBOR chứa tướng kín.

## 5. Trình tự thực thi và điểm dừng/gate

| Mốc | Gồm | Thực hiện | Exit gate / cho phép làm bước sau |
| --- | --- | --- | --- |
| **G0 — khóa baseline** | SEL-00 | Xác minh pin; capture fixtures, art map và danh sách test; review worktree dirty | File/source mapping, không động chạm upstream/runtime; ghi báo cáo baseline. |
| **G1 — luật/chọn an toàn** | SEL-01..06 | State-machine → Lua predicate/caching → kingdom → lifecycle → wire guard → RequestDialog | Unit contract + `test:connection` + Lua smoke; chọn sai luôn bị chặn; không double reply/auto reply. |
| **G2 — parity thị giác** | SEL-07..13 | Bổ sung metadata read-only; art cards; slots; faction; HP/companion; skill inspector; progress | Có screenshot desktop/portrait (fixture) và test dữ liệu registry; không có field giả/ảnh vỡ. |
| **G3 — responsive + a11y** | SEL-14..17 | Desktop rộng → portrait → landscape → keyboard/performance | Geometry/assertions tất cả viewport, focus/scroll/touch PASS; không phá các dialog khác. |
| **G4 — tích hợp** | SEL-18..19 | Run unit/E2E + Lua thật; native isolated QA; reconnect & privacy | Local/build và native QA evidence tách biệt; GameOver/cleanup xác nhận; không claim hosted từ local. |
| **G5 — nghiệm thu và phát hành tách biệt** | SEL-20 | Hosted gameplay + branch/release review với changelog, smoke plan & rollback | Chỉ đánh dấu hosted PASS khi đã quan sát đầy đủ; nghiệm thu thiết bị vật lý đã được bỏ khỏi scope theo quyết định của người dùng; phát hành là quyết định riêng có phê duyệt/phạm vi cụ thể. |

Các bước code nên chia thành diff nhỏ cho G1, G2, G3 và G4 để review độc lập. Trước từng mốc chạy `git status --short`; không reset/clean/checkout/commit/push thay đổi có sẵn. Trên checkout dirty đang có từ công việc khác, phân loại failure nền với failure mới bằng diff/tên test và ghi riêng.

### 5.1. Bộ lệnh kiểm tra khi triển khai

```bash
# Từ root repository
git status --short
git log -1 --oneline

# Kiểm tra package/frontend (test thực tế theo từng gate)
npm --prefix game/web run typecheck
npm --prefix game/web run typecheck:tools
npm --prefix game/web run test:connection
npm --prefix game/web run test:store
npm --prefix game/web run test:e2e
npm --prefix game/web run test:e2e:lua
npm --prefix game/web run build

# Nếu thêm test thuần cho lựa chọn:
cd game/web
npx --no-install tsx --test scripts/initial-general-choice.test.ts

# Sau chỉnh sửa từng mốc, từ root
git diff --check
npm run codex:checkpoint
```

**Điều kiện thực tế:** `test:e2e:lua` có thể dài và phụ thuộc chuẩn bị pinned upstream; kiểm `prepare:upstream` theo repo trước chạy. Native QA dùng runbook cô lập, cleanup port/process/tunnel; không dùng production để đóng gate. `build` chỉ sinh artifact local `game/web/dist`, không phải hosted deployment. Lệnh cụ thể thay đổi nếu script trong `package.json` thay đổi ở thời điểm thực thi; lấy script thực tế làm chuẩn.

## 6. Nguy cơ, cách tránh và quyết định còn mở

| Nguy cơ | Tác động | Kiểm soát |
| --- | --- | --- |
| Copy predicate `canMatch` sang TS, bỏ kiểm `getKingdom` | Bật CTA cho cặp không có kingdom được bật | Chỉ dùng Lua oracle read-only, kèm fixtures Wild/multi-kingdom. |
| Có hai slot nhưng CSS cũ max-width 520px | Lệch grid, cắt CTA trên điện thoại | Namespaced modal, grid-scroll riêng, snapshot/geometry tests. |
| `generalArtCandidates` có fallback base name | Dễ gắn hình variant sai nếu người xem hiểu là exact | Ưu tiên exact, chú giải/fallback neutral khi không xác minh art đúng variant; test số lượng/404 và mapping. |
| HP / companion metadata không sẵn từ adapter | UI hiển thị thông tin suy diễn sai | Thêm hàm Lua bounded; nếu chưa xác minh thì ẩn chỉ số thay vì đoán. |
| Info sheet / modal overlay lẫn nhau | Touch/keyboard click nhầm hoặc out-of-viewport | Reuse `SkillInfo`, `RequestDialog`, portal và z-index có chủ đích; test click inspector không chọn. |
| Render hàng chục thẻ gọi Lua nhiều lần | Lag/jank, timer giật | Tách timer component + memo; cache matching theo request, không Lua call trong render. |
| Request bị server hủy sau khi đã chọn xong | Stale reply / mất đồng bộ | Key requestId + receivedAt, expiry/busy guards, never auto-send. |
| Bài test cũ dùng `locator('button')` | Nhầm button chọn và button info | Dùng `.general-choice`, accessible role/name, test độc lập hai nút. |
| Thay đổi `styles.css` dài và nhiều override | Phá bàn chơi / responsive sẵn có | CSS namespace, test board không hồi quy ở portrait/landscape. |
| Shared checkout có thay đổi dirty/đang được phiên khác sửa | Ghi đè mất công việc | Chỉ sửa file ticket, so diff, tránh auto-format toàn bộ, checkpoint chỉ phần người thực hiện. |

**Các quyết định đã định sẵn:** P0 phải theo QML: không nhấn tướng thứ ba khi đã đủ cặp; bỏ chủ sẽ dồn phó lên; thế lực đa lựa chọn phải xác nhận; server xử lý timeout. Ưu tiên reuse asset và modal có sẵn. Không cần xin lại quyết định UX này khi bắt đầu code nếu không có chỉ đạo mới.

**Chỉ mở khi có evidence:** công thức hiển thị HP/companion chính xác trên QML (phải xác minh `GeneralCardItem`/registry trước khi hiển thị); free-assign/same-convert (phụ thuộc settings và server); thứ tự tối ưu các card trên mobile (không tự sắp xếp nếu server cố ý group theo kingdom). Những mục này không là điều kiện để bắt đầu G1.

## 7. Mẫu bằng chứng và sign-off cho từng mốc

Mỗi ticket có một bản ghi: `ID`, `git revision`, `pin list/hash`, `changed files`, `fixture nguồn`, `lệnh test thật`, `PASS/FAIL`, `viewport`, `giới hạn`, `ảnh/evidence đã sanitize`, `bước sau`, `rollback notes`. Với G4 bổ sung native QA instance/port riêng và xác nhận đã dọn process; với G5 bổ sung hosted revision, profile/browser mode, các stage thao tác và kết quả flow hosted. Không đưa credentials, token, nội dung `.env`, raw player hand/general, message body hoặc raw exception vào tài liệu/evidence.

**Cập nhật triển khai 23/10/2026:** G0 đã khóa baseline; G1–G2 đã triển khai vào `game/web`; G3 đã **PASS** local với offer 5/7/10/16/50 và đủ ma trận portrait `320×568, 360×667, 390×844, 412×915, 430×932`, landscape `667×375, 844×390, 932×430`, desktop `1280×800, 1440×900`, kèm no-horizontal-scroll, card đầu/cuối, CTA/progress, Enter/Space, Shift+Tab, ARIA/unavailable reason và timer khi mount 50 card. G4 local `test:e2e` **35/35**, `test:e2e:qa` **4/4**, server contract **51/51**, real-Lua **72/72**, unit/connection/build **PASS**; native isolated `general-pair-trace` **PASS** (two real clients/four seats, pair → hide → GameOver, không lộ card đối thủ), evidence sanitized tại [`cp08-general-pair-trace-multiplayer-live-1792728872776.json`](../../scratch/evidence/cp08-general-pair-trace-multiplayer-live-1792728872776.json). Native reconnect/privacy đã **PASS bounded** ở evidence mới bên dưới; hosted release gate vẫn **OPEN**. Nghiệm thu iPhone/Android vật lý được người dùng bỏ khỏi scope và không còn là điều kiện G5. Sau probe đã restore `tqsQa.enabled=false`, remove QA package/symlink, đóng tunnel/gateway và xác nhận native `9527` listening. Không suy diễn local/native bounded PASS thành hosted PASS; chưa commit/push/deploy.

**Lịch sử blocker native reconnect/privacy trong cùng ngày:** hai lần `general-pair-match-a --audit-bots --reconnect` trên QA instance cô lập ban đầu đều **FAIL trước popup**, nên không được tính là reconnect/privacy evidence: lần đầu dính startup race; lần thứ hai vào được login/room nhưng native `makeGeneralPile()` vượt execution limit tại `engine.lua:355`/`room.lua:143`, không phát `CustomDialog` (`nativeQaGateSeen=false`, `recovered=false`). Evidence metadata-only: [`reconnect-failure-1792729454175.json`](../../scratch/evidence/reconnect-failure-1792729454175.json) và [`reconnect-failure-1792729623192.json`](../../scratch/evidence/reconnect-failure-1792729623192.json). Một control sau đó bị loại vì room/account stale còn trong process sau lỗi native và không qua lobby; không dùng nó để kết luận client. Blocker này đã được xử lý bằng QA package/process root có auth environment, host idle và chẩn đoán bounded cho `makeGeneralPile`; kết quả PASS cuối cùng được ghi ở đoạn sau.

**Bằng chứng native reconnect/privacy sau khi xử lý blocker:** QA package tạm có source revision `d725bab6758e48ce45f126a5139853670a0ca3f9`, package SHA-256 `4cd9922c4bde473faa78160f2d8b517ce5e3a5ef7b2c1d488db8a0d36cbafd76`, cùng runtime MD5 `845498010a0c9f790254ec86e3dfc999` và dist-index SHA-256 `4cd035e816a806a41566bcc0773d455de5bf460ee8dd4fb500ccda94ccce6026`. Diagnostic QA metadata ghi nhận `makeGeneralPile` chạy với `generals=2388`, `disabled_packs=106`, `disabled_generals=0`, tạo `pile=241` trong **268.798 ms** ở control `general-pair-trace`; lượt full-match ghi nhận **1254.832 ms**. Control native **PASS** với hai client thật/bốn ghế, chọn cặp → che tướng → GameOver. Full-match [`cp08-general-pair-match-a-reconnect-live-1792731813045.json`](../../scratch/evidence/cp08-general-pair-match-a-reconnect-live-1792731813045.json) **PASS**, `recovered=true`, controlled WebSocket close → native `Reconnect` → board restore → GameOver; audit có 2 client thật + 2 native bot, `errors=0`, và privacy scrub xác nhận không còn raw logs. Phần public bot audit chỉ còn log Pair metadata; `boardPlayers`, `botNames`, `skillLogs`, `botSkillLogs`, `humanSkillActors` đều rỗng. Đã sửa runner để scrub đồng nhất các artifact `multiplayer`, `reconnect` và `gateway-restart` trong [`game/web/scripts/multiplayer-e2e/run.ts`](../../game/web/scripts/multiplayer-e2e/run.ts). Sau đó đã kill đúng native QA process, restore `tqsQa.enabled=false`, remove đúng QA package/symlink, dừng gateway/tunnel/temp runtime và khởi động lại native production-clean; kiểm tra cuối xác nhận `9527/9000` LISTEN. Đây là **native QA bounded PASS**, không phải hosted hay thiết bị thật.

**Hosted preflight mới nhất, chưa đóng G5:** đọc trực tiếp `https://tqsvn.pages.dev/` và `/gateway/healthz` đều trả **200**; `/gateway/manifest.json` giữ identity runtime MD5 `845498010a0c9f790254ec86e3dfc999`, bundle hash `5beabc83feac2d67`, `fileCount=5281`. Bundle public hiện chứa marker popup `Xác nhận tướng`, `Chọn lại` và `.general-choice`; đây chỉ xác nhận candidate đã phục vụ mã popup qua HTTPS. Evidence metadata-only được lưu tại [`cp08-general-popup-hosted-preflight-20261023.json`](../../scratch/evidence/cp08-general-popup-hosted-preflight-20261023.json). `npm --prefix game/web run test:e2e:public:unit` **5/5** và runner `--help` **PASS**. Hosted OAuth access đã được quan sát bằng Chrome profile hiện hữu `Đạt`, tạo được phòng QA và popup initial-general đã render; transition chọn chủ tướng cũng đã phản hồi. Lần đầu hết 30 giây trước khi xác nhận cặp, client chuyển BOT và sau đó GameOver; lần thử phòng thứ hai với 60 giây bị trạng thái bot chưa sẵn sàng, rồi server hiện **“Máy chủ đang tạm chặn IP kết nối”**. Đã dừng retry/bypass. Evidence partial metadata-only tại [`cp08-general-popup-hosted-gameplay-partial-20261023.json`](../../scratch/evidence/cp08-general-popup-hosted-gameplay-partial-20261023.json). Không dùng popup render/main-selection partial hoặc lobby access để thay thế valid-pair confirmation/GameOver/logout-relogin; G5/SEL-20 vẫn **OPEN** vì hosted flow, reviewed Git commit/tag và release sign-off còn thiếu. Thiết bị vật lý đã được người dùng loại khỏi scope.

**Release/rollback preflight read-only:** trên `tqs-native-qa-replacement`, `current` đang trỏ `ai-prompt4-20261022-prod-clean`; native, gateway và Quick Tunnel đều `active`, `9527/9000` LISTEN. Backup `freekill-hegemony-20261022T165727Z.tar.gz` mode `0600`, previous release `freekill-asio-source-0.1.17-prompt1` và launcher cũ đều còn; evidence metadata-only tại [`cp08-general-popup-release-preflight-20261023.json`](../../scratch/evidence/cp08-general-popup-release-preflight-20261023.json). Audit requirement-by-requirement cho SEL-20 được lưu tại [`cp08-general-popup-g5-audit-20261023.json`](../../scratch/evidence/cp08-general-popup-g5-audit-20261023.json): preflight là **PASS_PRECHECK_ONLY**, còn authenticated gameplay, reviewed Git commit/tag và release sign-off vẫn **OPEN**; physical-device evidence đã được user waiver.
