# QA Scenario Mode

## Mục đích

`QA Scenario Mode` là một chế độ dựng kịch bản chỉ dành cho test của web
client. Nó làm cho các điều kiện khó tái hiện bằng ngẫu nhiên trở thành điều
kiện có tên và có seed cố định, chẳng hạn:

- lá đầu tiên là `Sát`, `Đào`, hoặc `Vô Giải (Quốc Chiến)`;
- đối thủ có một lá úp và một trang bị để phát sinh `AskForCardChosen`;
- có đủ hai nhóm lá để phát sinh `AskForPoxi` với lựa chọn nhiều lá;
- có `Sát`/trang bị/`Đào` để phát sinh `AskForCardsAndChoice`;
- người chơi hấp hối ngoài hoặc trong Quyết chiến;
- dã tâm gia nhận `AskForChoices` để lập quốc.

Chế độ này không phải một nút gian lận trong client và không được bật bằng
tham số do người chơi gửi lên máy chủ production. Các file của nó nằm trong
`game/web/scripts/real-lua-e2e/`, không được import vào bundle production và
không được đóng gói vào mobile release.

## Cách hoạt động

```text
scenario plan (matcher + seed)
        │
        ▼
native FreeKill draw pile ──resolve──► card IDs của đúng package đang cài
        │                                      │
        └──── deterministic top + seeded tail ─┘
                                               │
                                               ▼
MoveCards + native request packet
                                               │
                                               ▼
React + GameConnection + Wasmoon/Lua
```

`qa-scenarios.ts` không ghi cứng card ID. Mỗi plan chỉ dùng một trong ba loại
matcher:

- `trueName`: tên luật của lá, ví dụ `slash` hoặc `peach`;
- `name`: tên biến thể wire, ví dụ `heg__nullification`;
- `type: equip`: bất kỳ lá trang bị hợp lệ.

Director lấy các ID từ `ClientInstance.draw_pile` của runtime native hiện tại,
đặt các matcher trong `drawSequence` lên đầu theo thứ tự khai báo, rồi
Fisher–Yates phần còn lại bằng seed 32-bit. Vì vậy package pin đổi ID vẫn không
làm test chọn nhầm lá; nếu runtime không có lá yêu cầu, resolver dừng với
`QaScenarioError` thay vì âm thầm chạy một kịch bản khác.

Mỗi `slot` có `drawIndex`, `owner`, `area` và `visible`. `drawIndex`
bắt buộc để cùng một lá trong `drawSequence` được dùng đúng một lần;
`visible=false` giữ đúng điều kiện lá úp của card selection. Sau khi dựng bàn,
director phát request native tương ứng (`AskForCardChosen`, `AskForPoxi`,
`AskForCardsAndChoice`, `AskForUseCard`, `AskForChoices`, `PlayCard`,
`AskForSkillInvoke` hoặc `AskForUseActiveSkill`) với request
ID mới và payload CBOR qua cùng bridge production mà browser đang dùng.
Riêng `hidden-yiji` không bơm trigger: native director giữ Quách Gia úp,
chờ gate để client gửi prelight, rồi gọi `room:damage` thật; runner chạy riêng
ba nhánh `negative`, `positive` và `skip`. `hidden-yiji-deputy` lặp nhánh
positive với Quách Gia ở phó tướng. `hidden-reveal` giữ Lục Tốn + Tôn Quyền
úp, yêu cầu `reveal_skill&` thật và kiểm combo `revealMain`;
`hidden-reveal-deputy` kiểm `revealDeputy`. `hidden-active` giữ Lục Tốn + Tôn
Quyền úp, để client chiếu Chế Hành thành regular skill, chọn một lá Sát trong
`PlayCard`, rồi để native reveal Tôn Quyền ở phó tướng trước effect;
`hidden-active-main` kiểm cùng luật khi Tôn Quyền ở chủ tướng. `hidden-view-as`
giữ Triệu Vân úp, chiếu Long Đảm thành regular skill, chọn một lá Thiểm trong
`PlayCard`, rồi để native đổi thành Sát sau khi mở đúng slot; bản `-main` kiểm
Triệu Vân ở chủ tướng.

## Ma trận hiện tại

| Scenario | Điều kiện được dựng | Lệnh chứng minh đã tới điểm cần test |
| --- | --- | --- |
| `draw-sequence` | `Sát → Đào → Vô Giải (Quốc Chiến)` ở đầu pile | `PlayCard` |
| `card-chosen` | tay đối thủ có lá úp, equip công khai | `AskForCardChosen` |
| `poxi` | tay + equip đối thủ, tối đa 2 lá | `AskForPoxi` |
| `cards-and-choice` | `Sát`, equip, `Đào`, filter Lua thật | `AskForCardsAndChoice` |
| `rescue-normal` | người khác 0 HP, `Đào` trong tay Self | `AskForUseCard` |
| `rescue-battle` | Self 0 HP, banner/kỹ năng Quyết chiến mới, `Đào` | `AskForUseCard` sau view-as `Đào → Rượu` |
| `founding` | thế lực dã tâm gia và danh sách quốc hiệu native | `AskForChoices` |
| `fazheng-enyuan` | bốn bước Long Đảm/Ân Oán, Di Kế và Phản Quỹ sau khi đã mở tướng | `AskForUseActiveSkill` |
| `hidden-yiji` | Quách Gia úp; native damage sau gate prelight | `AskForSkillInvoke` ở nhánh positive/skip; negative phải không có request Di Kế |
| `hidden-yiji-deputy` | Quách Gia ở phó tướng úp; native damage sau gate prelight | Invoke Di Kế phải mở đúng phó tướng, không được mở chủ tướng |
| `hidden-reveal` | Lục Tốn + Tôn Quyền úp; active helper native sau gate | `AskForUseActiveSkill` → `revealMain:::hs__luxun` |
| `hidden-reveal-deputy` | Lục Tốn ở phó tướng úp; active helper native sau gate | `AskForUseActiveSkill` → `revealDeputy:::hs__luxun` |
| `hidden-active` | Lục Tốn + Tôn Quyền úp; một lá Sát dự trữ | `PlayCard` → Chế Hành → mở Tôn Quyền, giữ Lục Tốn úp |
| `hidden-active-main` | Tôn Quyền ở chủ tướng úp; một lá Sát dự trữ | `PlayCard` → Chế Hành → mở chủ tướng Tôn Quyền, giữ Lục Tốn úp |
| `hidden-view-as` | Triệu Vân ở phó tướng úp; một lá Thiểm dự trữ | `PlayCard` → Long Đảm → mở phó tướng, đổi Thiểm thành Sát |
| `hidden-view-as-main` | Triệu Vân ở chủ tướng úp; một lá Thiểm dự trữ | `PlayCard` → Long Đảm → mở chủ tướng, đổi Thiểm thành Sát |

Kịch bản được kiểm tra bằng bài matrix duy nhất để không lẫn evidence giữa các
ca. Bài này kiểm cả điều kiện đầu vào, request ID, thao tác UI và reply native;
không chỉ kiểm tra một component cô lập.

## Chạy

Từ `game/web`:

```bash
npm run test:e2e:qa   # chỉ chạy matrix QA Scenario Mode
npm run test:e2e:lua  # toàn bộ real Lua/Wasmoon browser suite, gồm matrix này
```

Test thuần planner:

```bash
npx tsx --test scripts/qa-scenarios.test.ts
```

Các lệnh này dùng runtime pin local và socket fixture có kiểm soát; chúng không
tạo room, không đăng nhập tài khoản thật, không chạm Oracle và không gọi
gateway Render.

## Package native server-side `tqs_qa`

Đã triển khai lớp tương ứng cho live C++ tại
[`deploy/freekill-native/qa/tqs_qa`](../../deploy/freekill-native/qa/tqs_qa).
Đây là package đặc biệt chỉ được copy vào một runtime QA riêng; nó không nằm
trong `runtime/packages` của repository và không được đăng ký vào
`packages.db`. `init.lua` chỉ tự đăng ký khi `ServerConfig.tqsQa.enabled` là
`true` và manifest package có trạng thái `verified`.

Installer/verify:

```bash
deploy/freekill-native/scripts/install-qa-package.sh \
  --source deploy/freekill-native/qa/tqs_qa \
  --runtime /srv/tqs-qa/runtime \
  --allow-user qa-player-a,qa-player-b \
  --expected-revision "$(git rev-parse HEAD)"

deploy/freekill-native/scripts/verify-qa-package.sh \
  --source deploy/freekill-native/qa/tqs_qa \
  --runtime /srv/tqs-qa/runtime \
  --expected-revision "$(git rev-parse HEAD)"
```

Installer/verify cùng kiểm tra Git revision sạch, catalog SHA-256, package
tree SHA-256, allowlist, quota/timeout, config QA và việc `tqs_qa` không xuất
hiện trong `packages.db`. Vì vậy sau bất kỳ chỉnh sửa nào, revision mới phải
được commit và package QA phải được cài/verify lại; runtime cũ sẽ không được
coi là bản mới.

Kịch bản native được chọn bằng tên phòng đã xác thực ở server:

```text
TQSQA/<scenario-id>/<0xseed>
```

Director dùng các event/card API thật của FreeKill (`GamePrepared`,
`DrawInitialCards`, `GameStart`, `RoundStart`, `GameFinished`), cố định đúng
các matcher card trong catalog, gắn skill thật của general, và gọi native
`Dying`/`AskForPeaches`, Battle-Royal hoặc `GeneralShown` khi kịch bản yêu
cầu. Nó không thêm client cheat command; room prefix, seed, allowlist, số
ghế, quota và thời lượng đều bị kiểm ở server. Catalog native được test
lockstep với id/seed/expected command của browser catalog bằng
`npm --prefix game/web run test:qa-server-contract`.

Runner live hiện có identity gate độc lập: `TQS_RELEASE_MANIFEST` là bắt buộc
theo mặc định; runner đối chiếu MD5 `flist`, danh sách package và hash
`dist/index.html` local, rồi nếu có `TQS_LIVE_URL` còn fetch
`/gateway/manifest.json` và `/` của hosted candidate. Sai một byte hoặc thiếu
manifest sẽ dừng trước login/room creation. Chỉ dùng
`TQS_LIVE_ALLOW_UNPINNED=1` cho một lượt chẩn đoán có chủ ý và không được ghi
nhận là evidence release.

## Ranh giới với live C++

Fixture local có thể phát `PrepareDrawPile` và native request vì nó đóng vai
server packet fixture. Không được suy luận rằng query string hoặc `_mode` từ
client có thể điều khiển draw pile trên FreeKill C++ thật. Các evidence
NATIVE-LOCAL trước đây được chạy sau khi `tqs_qa` đã được cài/verify trong một
QA runtime cô lập; ma trận hidden khi đó đã chạy đủ ba nhánh Di Kế ở chủ tướng,
cùng các ca đối xứng Di Kế phó tướng, Gian Hùng chủ/phó, active reveal
chủ/phó, Chế Hành chủ/phó và Long Đảm ViewAs chủ/phó qua browser + gateway +
C++ thật. Đây là **NATIVE-LOCAL bounded evidence**, không phải hosted/official
release evidence. Checkout hiện tại không giữ executable/runtime QA hoàn chỉnh;
lần rerun gần nhất không phát readiness gate, nên không được suy ra package đang
được cài/bật hiện hành từ manifest tái dựng. Khi chạy lại, phải cài package vào
QA runtime riêng, verify cùng revision với source, rồi chạy room `TQSQA/...`
qua runner có release identity; `TQS_LIVE_ALLOW_UNPINNED=1` chỉ dành cho chẩn
đoán local có chủ ý.
Các điều kiện vận hành vẫn bắt buộc:

1. package không nằm trong package production/mobile release mặc định;
2. chỉ được load ở QA server riêng hoặc profile server tách biệt;
3. seed/scenario được xác thực bởi server, không tin raw request từ client;
4. chỉ account/room QA được allowlist, có quota và timeout;
5. lifecycle room luôn kết thúc sạch để không kích hoạt temporary-ban do room
   bị bỏ dở;
6. log/evidence phải sanitize card ID, payload riêng tư, credential và token.

Evidence NATIVE-LOCAL hiện hành của 12 ca hidden nằm trong
[`scratch/evidence`](../../scratch/evidence/); chúng kiểm request count, public
log, reveal đúng chủ/phó, card movement, `AskForChoices`/Gian Hùng, ViewAs conversion, GameOver và clean
disconnect trên hai browser client. Các scenario khác trong ma trận vẫn chỉ có fixture/local
evidence cho đến khi được chạy tương tự trên C++ thật. Evidence
này không thay đổi trạng thái official release, `PLAYABLE_MOBILE`, hay các gate
thiết bị/network đã được người dùng miễn.
