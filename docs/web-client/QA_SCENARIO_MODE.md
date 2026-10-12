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

## Ranh giới với live C++

Fixture local có thể phát `PrepareDrawPile` và native request vì nó đóng vai
server packet fixture. Không được suy luận rằng query string hoặc `_mode` từ
client có thể điều khiển draw pile trên FreeKill C++ thật. Nếu cần chạy cùng
ma trận trên server thật, bước tiếp theo phải là một package server-side riêng
(ví dụ `tqs_qa`) với tất cả điều kiện sau:

1. package không nằm trong package production/mobile release mặc định;
2. chỉ được load ở QA server riêng hoặc profile server tách biệt;
3. seed/scenario được xác thực bởi server, không tin raw request từ client;
4. chỉ account/room QA được allowlist, có quota và timeout;
5. lifecycle room luôn kết thúc sạch để không kích hoạt temporary-ban do room
   bị bỏ dở;
6. log/evidence phải sanitize card ID, payload riêng tư, credential và token.

Cho đến khi package đó được triển khai và có lịch live an toàn, bằng chứng của
`QA Scenario Mode` được phân loại là **local browser + Wasmoon/Lua PASS**; nó
không biến các gate Battle-Royal/founding trên C++ thật thành live PASS và
không thay đổi trạng thái official release.
