# CP19 — request inventory sau khi runtime skill hoàn tất

Cập nhật ngày 12/10/2026. Inventory này được chạy lại sau khi runtime đã nạp đủ
11 package upstream pin và đã sửa declaration `langmie → ty__langmie` có căn cứ.
Nó chỉ mô tả khả năng phát request trong Lua; local fixture và hosted evidence
được ghi riêng, không suy diễn caller live từ số lượng callsite.

## Lệnh và snapshot

```bash
node scripts/cp17-request-inventory.mjs \
  scratch/cp19-runtime.xV1eIs \
  > /tmp/CP19_REQUEST_INVENTORY.md
```

- Snapshot: `scratch/cp19-runtime.xV1eIs`.
- Lua files scanned: **4.717**.
- Package roots: `freekill-core` (305), `hegemony` (477), `mobile` (649),
  `ol` (1125), `overseas` (423), `shzl` (148), `sp` (112),
  `standard_ex` (53), `tenyear` (1218), `utility` (24), `yj` (183).
- Hai file định nghĩa request của core (`ltk/server/room.lua`,
  `ltk/client/client.lua`) được loại khỏi method count; helper/AI callsite vẫn
  được giữ ở cột `All matches`.
- Bản output đầy đủ có line number và callsite detail nằm ở
  `/tmp/CP19_REQUEST_INVENTORY.md` của phiên chạy; các con số nghiệm thu dưới
  đây được chép từ output đã quan sát, không phải số liệu từ report cũ.

## Kết quả theo request

| Ưu tiên | Lua method | Wire request | Renderer | Interactive | All matches | Trạng thái local/hosted hiện tại |
| --- | --- | --- | --- | ---: | ---: | --- |
| P1 | `askToChoice` | `AskForChoices` | `ChoicePanel` | 649 | 649 | Renderer + fixture PASS; rule-specific hosted matrix còn mở |
| P1 | `askToChoices` | `AskForChoices` | `ChoicePanel` | 39 | 39 | Renderer + fixture PASS; rule-specific hosted matrix còn mở |
| P0 | `askToChooseCard` | `AskForCardChosen` | `CardSelectionPanel` · single | 457 | 457 | Fixture PASS; caller targeted hosted PASS; broad matrix còn mở |
| P0 | `askToChooseCards` | `AskForPoxi` | `CardSelectionPanel` · multi | 129 | 149 | Fixture PASS; caller targeted hosted PASS; broad matrix còn mở |
| P0 | `askToChooseCardsAndChoice` | `AskForCardsAndChoice` | `CardsAndChoicePanel` | 12 | 12 | Fixture PASS; caller targeted hosted PASS; broad matrix còn mở |
| P0 | `askToChooseCardsAndPlayers` | `AskForUseActiveSkill` | `GameBoardScreen` + Lua scene | 126 | 126 | Renderer + fixture PASS; rescue/duel/founding live cases còn mở |
| P0 | `askToUseActiveSkill` | `AskForUseActiveSkill` | `GameBoardScreen` + Lua scene | 166 | 166 | Renderer + fixture PASS; view-as/rule-specific live cases còn mở |
| P1 | `askToUseCard` | `AskForUseCard` | `GameBoardScreen` + Lua scene | 73 | 73 | Renderer + fixture PASS; response-card live matrix còn mở |
| P0 | `askToChooseToMoveCardInBoard` | `AskForMoveCardInBoard` | `NativeDialogPanel` · boardMove | 23 | 23 | Renderer + fixture PASS; hosted chưa có |
| P0 | `askToArrangeCards` | `AskForArrangeCards` | `NativeDialogPanel` · arrange | 46 | 46 | Renderer + fixture PASS; hosted chưa có |
| P2 | `askToAG` | `AskForAG` | `NativeDialogPanel` · ag | 2 | 2 | Renderer + fixture PASS; hosted chưa có |
| P0 | `askToCustomDialog` | `CustomDialog` | `NativeDialogPanel` · QML allowlist | 15 | 15 | Renderer + fixture PASS; hosted caller matrix còn mở |
| P0 | `askToChooseSkills` | `CustomDialog` | `NativeDialogPanel` · skills | 10 | 10 | Renderer + fixture PASS; hosted chưa có |
| P0 | `askToChooseGeneralsAndChoice` | `CustomDialog` | `NativeDialogPanel` · generalsAndChoice | 9 | 9 | Renderer + fixture PASS; initial-general live riêng |
| P0 | `askForChooseCardNames` | `CustomDialog` | `NativeDialogPanel` · cardNames | 18 | 18 | Renderer + fixture PASS; hosted chưa có |
| P1 | `askForSkillInvoke` | `AskForSkillInvoke` | `SkillInvokePanel` | 0 | 1 | Renderer + fixture PASS; callsite direct do core parser/client định nghĩa |

## Hosted caller matrix đã chạy lại

CP21 chạy đúng nhánh caller manual bằng
`npm run test:e2e:multiplayer -- --manual` (không tính các lượt lifecycle-only
không có `--manual`). Runner dùng hai tài khoản thật, pool tướng native theo
caller, request ID và payload đã sanitize, rồi kiểm tra server đi đến GameOver →
result → lobby → disconnect. Bốn artifact mới nhất đều `result: PASS`,
`errors: []`:

| Ca | Caller/đích | Evidence |
| --- | --- | --- |
| Baseline room lifecycle + manual PlayCard | two-account room, one exact card/target/OK reply, GameOver/result/lobby/disconnect | `scratch/evidence/cp08-multiplayer-live-1791823425787.json` |
| `card-chosen` | Bàng Đức / `jianchu`, lá úp, đúng một reply | `scratch/evidence/cp08-card-chosen-multiplayer-live-1791823228504.json` |
| `poxi` | Đặng Chi / `weimeng`, nhiều lá `selected-2` | `scratch/evidence/cp08-poxi-multiplayer-live-1791823274505.json` |
| `cards-and-choice` | Tưởng Khâm / `shangyi`, `{cards, choice}` với view rỗng hợp lệ | `scratch/evidence/cp08-cards-and-choice-multiplayer-live-1791823328583.json` |

Rescue/Battle-Royal/founding/view-as và hosted native Arrange/Move/ChooseSkill,
generals+choice, card names, KnownBoth vẫn là các probe gameplay riêng; chưa
được gộp vào bốn caller PASS ở trên. Các failure cũ vẫn giữ để audit, không
được đổi thành PASS và không retry khi server còn cơ chế temp-ban.

## Bất biến cần giữ

- Inventory không thay thế Lua rule source: `pattern`, min/max, feasible/target
  và `view_as` vẫn do runtime quyết định.
- Một request chỉ được reply một lần, đúng CBOR type và `requestId`; stale,
  expired, duplicate, disconnect và replacement phải cleanup an toàn.
- Lá úp không được lộ face metadata hoặc identifier riêng tư.
- Native dialog chỉ render QML/model allowlist; payload cyclic, oversized hoặc
  component lạ phải fail closed.
