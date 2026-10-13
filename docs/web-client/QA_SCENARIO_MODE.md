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
`AskForCardsAndChoice`, `AskForUseCard`, hoặc `AskForChoices`) với request
ID mới và payload CBOR qua cùng bridge production mà browser đang dùng.

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
`npm run test:qa-server-contract`.

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
client có thể điều khiển draw pile trên FreeKill C++ thật. Với C++ thật, bước
triển khai package đã có; bước live tiếp theo là cài package vào QA runtime
riêng, verify cùng revision với source, rồi chạy room `TQSQA/...` qua runner
đã pin release identity. Các điều kiện vận hành vẫn bắt buộc:

1. package không nằm trong package production/mobile release mặc định;
2. chỉ được load ở QA server riêng hoặc profile server tách biệt;
3. seed/scenario được xác thực bởi server, không tin raw request từ client;
4. chỉ account/room QA được allowlist, có quota và timeout;
5. lifecycle room luôn kết thúc sạch để không kích hoạt temporary-ban do room
   bị bỏ dở;
6. log/evidence phải sanitize card ID, payload riêng tư, credential và token.

Cho đến khi QA runtime native riêng được cài và có live evidence của từng
scenario, bằng chứng của `QA Scenario Mode` vẫn được phân loại là **local
browser + Wasmoon/Lua PASS**; package source/installer đã PASS syntax, catalog
contract và fixture installer nhưng chưa chứng minh một hosted C++ room mới.
Nó không thay đổi trạng thái official release, `PLAYABLE_MOBILE`, hay các gate
thiết bị/network đã được người dùng miễn.
