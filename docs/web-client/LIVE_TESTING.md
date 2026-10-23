# Kiểm thử web client với FreeKill thật

Các lệnh bên dưới chạy trong `game/web/` và dùng Node 22+, Chrome. Các bài
**native legacy** dùng package Git đã pin trong `scratch/upstream/`, khởi động
gateway/Vite tạm và đóng process sau bài test. Runner **public Google OAuth**
ở mục riêng truy cập trực tiếp bản đã deploy qua HTTPS/WSS và dùng Chrome
profile QA riêng, không cần Vite/gateway local.

## Cấu hình một lần cho native legacy

```sh
npm run configure:live
```

Mặc định nối replacement VM `161.33.209.212:9527`. Có thể đặt `TQS_LIVE_HOST` / `TQS_LIVE_PORT` để chọn server thử khác, và `TQS_PACKAGE_SOURCE` để chọn thư mục chứa ba checkout `freekill-core`, `hegemony`, `utility`.

Script lấy `UpdatePackage` bằng một handshake có MD5 cố ý sai. Theo source FreeKill được pin, server kiểm tra MD5 **trước** kiểm tra mật khẩu/đăng ký; bước dò package không tạo tài khoản. Script đối chiếu enabled packages, commit và trạng thái Git, xuất các blob Lua/JSON/QML/JS từ Git rồi sinh `flist.txt` theo thuật toán C++. Snapshot nằm riêng trong `scratch/live-web-test/`.

Không dùng chỉ các file hiện trên working tree để sinh hash: sparse checkout có thể thiếu QML dù Git báo sạch. Nếu partial clone thiếu một blob cần thiết, script báo `Missing pinned Git blob`; cần bổ sung đúng blob của commit pin vào cache Git hoặc dùng checkout đầy đủ. Script không tự cập nhật revision hay thay đổi sparse checkout.

Thông tin tài khoản test mới được sinh ngẫu nhiên và lưu trong `~/.codex/secrets/tqs-live-test.env`, quyền `0600`, ngoài repository. Có thể chọn đường dẫn khác bằng `TQS_LIVE_CONFIG`. Script không in giá trị tài khoản/mật khẩu và từ chối ghi đè cấu hình đã tồn tại. Tài khoản chỉ được server đăng ký khi chạy test đăng nhập lần đầu thành công; các lần sau dùng lại cùng cấu hình.

## Native QA: provenance P1 và ticket xác thực được phép

P0/P2 native không được chạy trên `current` hoặc trên runtime chỉ “gần giống”
P1. Runner hiện khóa ba lớp provenance của baseline: `freekill-core` của
`smart_ai.lua`, `room.lua`, và QA SmartAI overlay; đồng thời bắt buộc
`TQS_QA_EXPECTED_RUNTIME_MD5` trùng `runtime/flist.txt` của runtime cô lập. QA
package vẫn là candidate hiện tại và phải có `TQS_QA_EXPECTED_REVISION`; điều đó
cho phép overlay P0/P2 thay đổi có chủ đích mà không làm lẫn public core với
baseline. Nếu thiếu một biến identity, runner dừng trước khi mở gateway/browser.

Replacement VM giữ secret game trong `/etc/tqs-game-auth.env` với quyền root,
không đưa secret về máy phát triển. Khi không thể dùng `TQS_LIVE_TICKET_SECRET`
trong một secret store cục bộ đã được phê duyệt, dùng helper SSH chỉ đọc:

```sh
TQS_LIVE_NATIVE_QA=1 \
TQS_LIVE_TICKET_HELPER="$PWD/game/web/scripts/multiplayer-e2e/mint-qa-ticket-via-ssh.mjs" \
TQS_LIVE_QA_SSH_ALIAS=tqs-native-qa-replacement \
TQS_LIVE_GATEWAY_TARGET=http://127.0.0.1:<local-gateway-port> \
TQS_QA_EXPECTED_RUNTIME_MD5=<isolated-runtime-flist-md5> \
npm run test:e2e:multiplayer -- --audit-bots
```

Helper chỉ gửi một script Python qua `ssh -T -o BatchMode=yes` tới
`sudo -n python3 -`; Python đọc `TQS_GAME_TICKET_SECRET` trên VM, ký TQS1 trong
bộ nhớ và trả về đúng ticket ngắn hạn. Không dùng SCP, không in secret, không
ghi secret vào log/evidence. Cổng native QA phải đi qua một SSH tunnel riêng;
`TQS_LIVE_GATEWAY_TARGET` chỉ là gateway đã nối tới cổng cô lập đó. Hai tài
khoản trong file cấu hình local phải nằm trong allowlist QA của package đang
chạy; không dùng tài khoản production.

Trước P0/P2, ghi lại ở evidence cả `runtimeMD5`, binary SHA-256, source
revision, QA package/catalog SHA-256 và browser `dist/index.html` SHA-256. Nếu
không còn binary/flist đúng lịch sử P1, tạo identity cô lập mới rồi chạy lại
P1 baseline trong chính identity đó; không gắn nhãn PASS cho một phép so sánh
giữa hai provenance khác nhau. Chỉ sau P0 thật-handler + synthetic PASS mới
chạy P2 differential/privacy, rồi mới mở P3 reconnect.

## Public OAuth E2E sau deploy (Google, tài khoản QA đã được cấp quyền)

Bộ kiểm thử public mới chạy trên **chính** `https://tqsvn.pages.dev/` và gateway
`wss://tqsvn.pages.dev/gateway/ws`, dùng màn hình Google hiện hành. Không dùng
form username/password, QA preauth localhost, mật khẩu/ticket giả hoặc fixture.
Chỉ chạy khi tài khoản Google QA đã được cấp quyền vào game và không có ván đang
chơi trên chính tài khoản đó. Cần Node/tsx, Playwright và Google Chrome cài sẵn.

Đăng nhập tài khoản QA **một lần** trong cửa sổ Chrome dành riêng cho runner:

```sh
cd game/web
TQS_PUBLIC_QA_EMAIL='<approved-qa-email>' npm run test:e2e:public -- --enroll
```

Chọn đúng tài khoản QA và hoàn tất Google/2FA bằng tay trong cửa sổ Chrome.
Runner chỉ PASS khi Firebase ID token có email QA đã xác thực và backend cấp
session thật để vào được sảnh qua WebSocket; sau đó ngắt kết nối khỏi sảnh.
Chrome profile được giữ riêng tại `~/.codex/secrets/tqs-public-oauth-chrome-profile`
(thư mục quyền `0700`, không nằm trong repo). Có thể đặt đường dẫn khác bằng
`TQS_PUBLIC_QA_PROFILE`, nhưng tuyệt đối giữ ngoài repo/CI artifacts và giới
hạn quyền truy cập. Profile chứa dữ liệu đăng nhập thật: chỉ dùng trên runner
riêng, không chia sẻ, upload, commit hoặc lưu làm Playwright storageState.

Sau mỗi lần deploy, chạy **một lệnh** (với cùng Chrome profile và email):

```sh
cd game/web
TQS_PUBLIC_QA_EMAIL='<approved-qa-email>' npm run test:e2e:public
```

Runner headless xác minh HTML public, Google/Firebase session của đúng QA account,
vào sảnh, WebSocket WSS cùng origin có gửi/nhận, tạo phòng `new_heg_mode` 2 ghế,
thêm bot, bắt đầu, chọn cặp chủ/phó tướng hợp lệ, bật BOT chơi hộ (native Trust),
chờ GameOver, trở về sảnh, ngắt socket, đăng xuất Firebase bằng **Đổi tài khoản
khác**, đăng nhập Google lần nữa và vào sảnh qua một WebSocket mới. Popup Google
có bộ chọn tài khoản chỉ click email QA khớp tuyệt đối. Nếu Google yêu cầu lại
mật khẩu/2FA, hết phiên hoặc chặn Chrome automation, lệnh **FAIL** với mã giai
đoạn an toàn; mở lại `--enroll` bằng tay để làm mới profile, rồi chạy lệnh hậu
deploy. Không có cơ chế né Google challenge hoặc ngụy tạo OAuth trong production.

Mặc định chờ 75 giây cho từng giai đoạn UI (240 giây khi enroll), tối đa 15 phút
cho ván; tùy chỉnh `TQS_PUBLIC_UI_TIMEOUT_MS` và `TQS_PUBLIC_MATCH_TIMEOUT_MS`
(milliseconds) nếu máy chủ chạy chậm. Ván chạy trên production thật, có thể tạo
phòng và kéo dài lâu hơn dự kiến, nên dùng khung thời gian QA ít người chơi.
Có thể đặt `TQS_CHROME_PATH` cho Chrome cài ở vị trí khác, và `TQS_PUBLIC_URL`
cho deployment HTTPS cùng cấu trúc gateway/session (mặc định là Pages production).
Khi timeout giữa ván, runner thử giữ native Trust trước khi đóng Chrome; kết quả
vẫn FAIL, cần kiểm tra phòng và khả năng temp-ban trước khi chạy lại.

Evidence ở `scratch/evidence/public-oauth-e2e/*.json` (file `0600`) chỉ ghi
PASS/FAIL, mã giai đoạn, bộ đếm WebSocket và số lần xác minh session; **không**
lưu email, mật khẩu, JWT, GameTicket, header, frame/payload WebSocket, dữ liệu
bài/tướng riêng, screenshot, console error hay raw exception. Lệnh
`npm run test:e2e:public:unit` kiểm tra hợp đồng nhận diện WSS/email/URL và
quy tắc che thông tin nhạy cảm mà không cần tài khoản thật. PASS unit/local
không thay thế PASS OAuth/GameOver public thật.

## Kiểm chứng đăng nhập legacy cho native QA cô lập

```sh
npm run test:e2e:login
```

Lệnh legacy này vẫn dùng form username/password của runner snapshot cũ, **không
phù hợp để nghiệm thu Google OAuth public hiện tại**. Dùng `test:e2e:public`
ở mục trên khi kiểm tra bản đã triển khai; không gắn PASS của legacy vào public.

Runner tự đọc cấu hình private, phục vụ bundle từ snapshot, chạy React trong Chrome ở viewport 390×844 và gửi `Setup` qua Gateway đến FreeKill C++. Điều kiện PASS gồm challenge RSA, đúng một `Setup`, server phản hồi `Setup` + `EnterLobby`, Lua xử lý thành công, React hiển thị sảnh/đã kết nối, gửi `RefreshRoomList`, không có lỗi JS/Lua/application, rồi nút ngắt kết nối đưa UI về login. Bài này không tạo/vào phòng hoặc bắt đầu ván.

```sh
TQS_LIVE_HOST=161.33.209.212 npm run test:e2e:live
```

Lệnh trên chỉ kiểm tra **pre-auth**: gói `Setup` bị chặn tại browser, dùng MD5 fixture; PASS không chứng minh đăng nhập. Không có `--login`, runner luôn chặn gửi dữ liệu tới server.

## Nghiệm thu live bộ tướng/bài UI-02 — 11/10/2026

```sh
TQS_LIVE_HOST=161.33.209.212 npm run test:e2e:live -- --room-pools
```

Runner dùng cấu hình test riêng đã có và Chrome mobile + Lua/Wasmoon + Gateway + FreeKill C++ thật. Bài này chủ động tạo phòng Quốc Chiến, tắt `hegemony_standard` (GeneralPack) và `hegemony_cards` (CardPack), kiểm tra `CreateRoom`/`EnterRoom` máy chủ echo đúng, chọn cặp tướng hợp lệ, kiểm tra từng tướng được cung cấp và ID bài trong `PrepareDrawPile` bằng Lua upstream. Sau đó bật Trust để BOT chơi đến `GameOver`, bấm về sảnh và ngắt sạch; cần dành thời gian cho cả ván và không chạy trùng tài khoản đang sử dụng.

**Kết quả đã quan sát: PASS (exit 0).** Preview 241/213 → 196/109; C++ cung cấp 5 tướng, 0 từ GeneralPack bị tắt; draw pile 109/109 ID duy nhất, 0 lá từ CardPack bị tắt; nhận `GameOver`, nút `Về sảnh` hoạt động. Evidence không chứa mật khẩu/hand riêng: `scratch/evidence/ui-02-live-cpp-2026-10-11.json`, ảnh `ui-02-live-{lobby,room,board,finished}-2026-10-11.png`. Đây là kiểm thử C++ live trên Chrome, **chưa phải iOS/Android vật lý**. Không thay server/deploy.

## Kiểm chứng build đã deploy qua HTTPS/WSS

Đặt `TQS_LIVE_URL` để runner mở chính bản build đóng băng và dùng `/gateway` của deployment. Chế độ này không khởi tạo gateway/Vite thứ hai và không cần import source trong trang. Dùng `--ui-translations` để tạo ván bot thật, chọn tướng, bật native Trust, chờ GameOver, về sảnh và ngắt sạch. Không chạy cùng tài khoản đang chơi.

```sh
TQS_LIVE_HOST=161.33.209.212 \
TQS_LIVE_URL=https://pvc-gotta-soundtrack-buses.trycloudflare.com \
TQS_UI01_EVIDENCE_DIR=../../scratch/evidence/new-deployment-verification \
npm run test:e2e:live -- --ui-translations
```

Runner kiểm tra RSA/Setup/EnterLobby thật, GameOver, lỗi JS/Lua/console, nhật ký và diễn biến công khai ở viewport 390px, không tràn ngang. Evidence chỉ chứa văn bản DOM công khai và metadata trình bày; không lưu frames, bài kín hoặc thông tin đăng nhập. Bộ dò còn sót chuỗi là phép rà cú pháp, chưa chứng minh mọi câu đúng nghĩa; đọc `unresolved` trong JSON ngay cả khi ván hoàn tất.

`scripts/audit-display-text.ts output.json evidence.json ...` xử lý lại văn bản DOM lịch sử bằng lớp hiển thị hiện tại, ghi SHA-256 của input và kiểm riêng hai câu hủy mục tiêu. Script không sửa input và từ chối ghi đè audit đã tồn tại. Kết quả này không thay thế quan sát live.

## Hồi quy cấu hình snapshot

```sh
npm run test:live-config
```

Kiểm tra thứ tự file/hash theo native, chuẩn hóa CRLF và trường hợp sparse checkout thiếu QML. Hai bài này chạy hoàn toàn local, không dùng tài khoản hoặc server thật.

## Bằng chứng 10/10/2026

- Live package revisions khớp `deploy/freekill-native/versions.env`.
- Pre-auth Chrome → Wasmoon → Gateway → FreeKill C++: PASS.
- Đăng nhập thật: PASS; 808 Lua/JSON files, server chấp nhận MD5 `a2a4b0af428f971c2642f11bd4aef162`.
- Lỗi đã sửa: snapshot từ sparse working tree bỏ sót bốn QML Hegemony, khiến MD5 `0855245c3bc1d72acdd21e2b3d003b3d` bị server từ chối trước đăng ký. Xuất đầy đủ blob Git sửa được lỗi; không thay đổi server.
- Browser hiển thị đã thao tác tạo phòng Quốc Chiến hai ghế, thêm bot, StartGame, chọn `os_heg__dongyun` + `os_heg__fuqian`, server tiếp tục ván và gửi AskForChoices. Đã sửa notification cần CBOR TEXT, Self bị thiếu ở room store và `_game` settings cho chọn tướng.
- AskForChoices đã có bảng chọn mới, `npm run test:choices` 2/2 và Lua smoke PASS, ở lần thử đầu chưa thử lại live vì server trả `you have been temporarily banned!` trước login. Khi đó chưa đánh bài/skill hoặc nhận GameOver có kết quả hợp lệ; kết quả mới ở phần bên dưới.
- Tiếp tục thử UI lúc ~16:40/~16:50 UTC: vẫn temp-ban. Đã chuyển trang 5174 sang preview ổn định.
- `test:e2e:lua` nay 13/13 PASS (socket fixture): thêm ChoicePanel và PlayCard qua GameBoardScreen/GameplayControls với Lua thật. Tìm và sửa scene ban đầu chỉ có typed updates, thiếu _new cho hand/photos/buttons, khiến web bỏ hết item. Smoke chứng minh chọn Sát → target → OK sinh CBOR array/map đúng, không duplicate. Hand counts và phase labels có kiểm tra; đây vẫn là bằng chứng local.

## Thử ván trên giao diện hiển thị

Chạy gateway với snapshot cấu hình private, build rồi dùng preview ổn định; mở URL local trong browser hiển thị để người dùng quan sát. Không thay source/HMR hoặc reload/disconnect khi đang trong ván. Source FreeKill pin có cơ chế temp-ban khi rời ván chưa kết thúc; duration thực tế phụ thuộc server. Nếu nhận ErrorDlg temp-ban, chờ server hết chặn, không đổi IP/account để vượt chặn. Không chạy test login bằng cùng account đồng thời với ván đang mở.

Lưu ảnh bàn chơi ngay khi start, khi chọn bài/target và GameOver. Login runner chỉ chứng minh đăng nhập; test Lua fixture chỉ chứng minh callback/format local, không thay thế kiểm chứng gameplay live.

## Ván bot hoàn chỉnh live — đêm 10–11/10/2026

Sau ~16:54 UTC, tài khoản cũ đăng nhập được; không đổi IP/account để vượt chặn. Browser hiển thị 5174 trên preview ổn định đã tạo phòng Quốc Chiến 2 ghế, thêm bot, chọn Biện Phu Nhân + Điển Vi, phản hồi Vô Giải, revealAll, dùng Sát/target/OK và hai lần Cường Tập (bỏ bài tay rồi vũ khí trang bị). HP bot 3→2→1→0; server GameOver winner `3` trùng Self.id=3: thắng. Bấm Rời phòng sau kết thúc và quan sát trở về sảnh. Không có console error/warning trong ván. Trace 614 packets, 10 request replies mỗi ID đúng một lần, chỉ command/type/requestId/direction; không lưu auth/private hand.

Bằng chứng ở `scratch/evidence/live-game-complete-2026-10-11.json` và ảnh `live-game-{start,board,choices,card-target,after-skill}-2026-10-10.png`, `live-game-finished-2026-10-11.png`, `live-game-back-lobby-2026-10-11.png`. Scratch không đưa vào Git.

Ván này xác nhận GameOver từ server; UI lúc đó chỉ trở về phòng chờ. Sau ván đã thêm GameResultPanel thắng/thua/hòa, giữ tên người thắng khi bot bị xóa, Về sảnh và cleanup vòng đời. Store 13/13, Lua browser 14/14 và build PASS. Panel kết quả mới chưa được quan sát trên GameOver live mới. Chưa có bằng chứng dùng Thiểm/Đào hợp lệ, view-as, card-chosen/Poxi/AG, hai người/reconnect hoặc iOS/Android thiết bị thật; không đánh dấu toàn bộ ma trận/mobile hoàn thành.

## Dialog chọn bài — 11/10/2026

`npm run test:card-selection` 2/2 và `npm run test:e2e:lua` 18/18 PASS trên Lua/Wasmoon thật, socket fixture. Chọn một lá dùng AskForCardChosen với integer reply; native chọn nhiều lá dùng AskForPoxi/rule AskForCardsChosen với array reply. Bài úp chỉ có token riêng mỗi request; trang bị công khai có tên/chất/số. Các case mới kiểm tra min/max/pattern, cancellation, stale/expiry/duplicate, cleanup reentrant và MoveCards sau lấy/bỏ bài. Ảnh panel fixture ở `scratch/evidence/card-selection-lua-fixture-2026-10-11.png`.

Lần thử live mới login/start/reveal, dùng Thiểm và Vô Giải thành công qua UI/log; chưa tới AskForCardChosen của Self. Ngọc Tỷ gọi Tri Kỷ Tri Bỉ rồi AskForCardsAndChoice xem bài chưa hỗ trợ. Backend sau đó đóng socket; lần login lại thực tế trả temp-ban. Không có bằng chứng server nhận dialog chọn bài mới; nguyên nhân đóng chưa được xác nhận từ log server. Ảnh blocker đã xóa các ô credentials ở `scratch/evidence/card-selection-live-blocked-2026-10-11.png`. Cần triển khai dialog xem bài và kiểm chứng lại sau khi server hết chặn.

### Bổ sung xem bài và lần thử khoảng 07:45–07:47 ngày 11/10

AskForCardsAndChoice đã có parser/panel/reply `{cards, choice}`, xem bài min=max=0, empty view, min/max/disabled, native Lua choiceFilter và cancel-only. Cards-and-choice unit 2/2, browser Lua 22/22, mock browser 16/16, smoke/typecheck/build PASS. Ảnh `cards-and-choice-view-lua-fixture-2026-10-11.png` là socket fixture, chưa có live acceptance cho bảng xem bài mới.

Cùng tài khoản đăng nhập lại được và tạo ván Bàng Đức + Kiển Thạc với bot Tôn Dực. Sát → kích hoạt jianchu → AskForCardChosen thật: ba bài úp, giáp công khai 火浣衣 ♦12. Chọn giáp, panel đóng và ván tiếp tục, bot HP 3→2/log 19→22. Không có trace đầy đủ; không nhận GameOver mới. Backend sau đó đóng socket, lần login lại thực tế nhận temp-ban. Giữ ticket GAME-03A mở cho xem bài mới, chọn tay úp, multi/Poxi và lấy/bỏ bài live. Ảnh blocker đã xóa credentials ở `cards-and-choice-live-blocked-2026-10-11.png`; tường thuật phạm vi bằng chứng ở `cards-and-choice-live-attempt-2026-10-11.json`. Không reload/disconnect trong ván hoặc đổi account/IP để vượt chặn.

## Điều tra closed/temp-ban và tránh timeout (11/10/2026)

`you have been temporarily banned!` được server C++ gửi khi IP nằm trong
`temp_banlist`; bản ghi lịch sử này được tạo khi cấu hình còn 20 phút, policy
production hiện hành đã giảm còn 5 phút. Với source-built native runtime, patch
reconnect chuyển kiểm tra temp-ban sau xác thực mật khẩu và chỉ cho phép tài
khoản đã xác thực reconnect khi player của chính tài khoản đó vẫn còn trong
room đang chơi; tài khoản mới hoặc room đã kết thúc vẫn bị chặn. AMD64 static
artifact hiện tại chưa chứa C++ patch này. QA runner dùng runtime riêng với
`tempBanTime=0`. Source patch cũng dời capacity check sau xác thực để player
offline đang giữ chỗ được reconnect; tài khoản mới vẫn nhận `server is full!`
khi đủ capacity. Chưa claim production active cho đến khi thay static artifact
bằng source-built runtime và đọc lại identity trên VM.

Source Lua pin cộng thời gian các request timeout vào `_timewaste_count`, kick người đang online khi tổng đạt 70 giây. Người bị ngắt phiên trong ván khi còn sống có thể bị xử lý như bỏ ván và temp-ban. Không suy diễn mọi backend close đều do timeout; cần log server để xác nhận nguyên nhân cụ thể.

Client cung cấp BOT chơi hộ bằng native Trust (server xác nhận NetStateChanged), countdown và cảnh báo rời/ngắt ván. Khi tạm nghỉ, bật BOT chơi hộ và giữ kết nối/trang mở. Trust không bảo vệ nếu đóng tab, mất mạng hoặc gateway bị dừng. Không auto-reply hay tự bật BOT thay người dùng.

Kiểm chứng login/heartbeat lâu hơn giới hạn TTL mặc định của source C++ (6 nhịp 30 giây):

```bash
TQS_LIVE_HOST=161.33.209.212 TQS_LIVE_IDLE_SECONDS=210 npm run test:e2e:login
```

Runner chờ ở sảnh, không tạo ván; yêu cầu mỗi Heartbeat thật có đúng một notification đáp lại và UI vẫn online, sau đó ngắt sạch ở sảnh. Có thể đặt `TQS_LIVE_EVIDENCE_PATH` trỏ đến PNG trong scratch để lưu ảnh sảnh sau khi đã bảo đảm không còn trường tài khoản/mật khẩu trong DOM. Không chạy cùng account đang chơi.

Recovery thực tế 11/10: probe nhận challenge lại lúc 08:07:37; runner cuối (HMR tắt, capture riêng socket game) **PASS ~08:20** login + sảnh 210s, **7/7 heartbeat**, không JS/Lua/application errors và ngắt sạch ở sảnh. Ảnh `scratch/evidence/temp-ban-recovery-lobby-2026-10-11.png` đã inspect. Không tạo ván hoặc nghiệm thu BOT Trust live trong recovery. Nguyên nhân đóng ván trước đó chưa xác nhận từ log VM.
