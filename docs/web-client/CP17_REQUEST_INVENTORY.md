# CP17 — đối chiếu request thực tế và renderer

> Cập nhật CP19 (12/10/2026): sau khi runtime đã nạp đủ 11 package upstream và audit skill đã PASS, request inventory được chạy lại trên snapshot `scratch/cp19-runtime.xV1eIs`. Code bridge/fixture đã hoàn tất phạm vi hiện tại; các dòng “còn mở” chỉ còn caller/rule-specific live evidence và device QA, không dùng local fixture để suy diễn hosted PASS.

Artifact summary chi tiết mới nằm ở [CP19_REQUEST_INVENTORY.md](CP19_REQUEST_INVENTORY.md). Output đầy đủ có line number/callsite detail được tạo bằng lệnh bên dưới. Inventory là source-level: callsite cho biết package có thể phát request, còn evidence chỉ được đánh dấu theo kết quả test/live đã quan sát; helper/AI/parser vẫn được tách khỏi cột `Interactive callers`.

## Cách tái tạo

```bash
node scripts/cp17-request-inventory.mjs \
  scratch/cp19-runtime.xV1eIs \
  > /tmp/CP19_REQUEST_INVENTORY.md
```

Lệnh trên xuất bảng và line number đầy đủ ra file tạm để review. Snapshot CP19 có **4.717 file Lua**: `freekill-core` 305, `hegemony` 477, `mobile` 649, `ol` 1125, `overseas` 423, `shzl` 148, `sp` 112, `standard_ex` 53, `tenyear` 1218, `utility` 24, `yj` 183. Hai file định nghĩa request của core bị loại khỏi method count; helper/AI vẫn hiện trong `All matches`.

## Kết luận ưu tiên

| Ưu tiên | Request thực tế | Caller tương tác | Renderer hiện có | Bằng chứng hiện tại | Việc cần đóng |
| --- | --- | ---: | --- | --- | --- |
| P1 | `AskForChoices` | 688 | `ChoicePanel` | Fixture PASS; hosted rule matrix còn mở | Rà rescue/duel/lập quốc và cancel/expiry |
| P0 | `AskForCardChosen` | 457 | `CardSelectionPanel` một lá | Fixture + targeted hosted PASS | Broad caller/cancellation/expiry/reconnect |
| P0 | `AskForPoxi` | 129 (149 cả helper) | `CardSelectionPanel` nhiều lá | Fixture + targeted hosted PASS | Broad caller/cancellation/expiry/reconnect |
| P0 | `AskForCardsAndChoice` | 12 | `CardsAndChoicePanel` | Fixture + targeted hosted PASS | Các choice filter/cancellation/expiry/reconnect |
| P0 | `AskForUseActiveSkill` | 292 | `GameBoardScreen` + Lua scene | Renderer + fixture PASS; targeted hosted matrix còn mở | Cứu Đào, quyết chiến/lập quốc, view-as |
| P1 | `AskForUseCard` | 73 | `GameBoardScreen` + Lua scene | Renderer + fixture PASS | Response-card/Thiểm/Đào và view-as |
| P0 | `AskForArrangeCards` | 46 | `NativeDialogPanel` arrange | Fixture PASS, hosted chưa có | Caller ArrangeCards trên ván thật |
| P0 | `AskForMoveCardInBoard` | 23 | `NativeDialogPanel` boardMove | Fixture PASS, hosted chưa có | Caller boardMove trên ván thật |
| P0 | `CustomDialog` | 52 | `NativeDialogPanel` QML whitelist | Fixture PASS, hosted caller matrix còn mở | ChooseSkill, generals+choice, card names, KnownBoth |
| P1 | `AskForSkillInvoke` | 0 direct / 1 all | `SkillInvokePanel` | Fixture PASS | Xác nhận trong hosted skill flow phù hợp |
| P2 | `AskForAG` | 2 | `NativeDialogPanel` AG | Fixture PASS, hosted chưa có | Giữ regression fixture |

## Bất biến nghiệm thu cho mỗi ca

- Lua là nguồn sự thật cho `pattern`, min/max, feasible/targets và `view_as`; React không tự tái lập luật.
- Một request chỉ được trả lời một lần bằng CBOR đúng kiểu và đúng `requestId`; không gửi reply stale/duplicate sau cancel, timeout, reconnect hoặc request bị thay thế.
- Bài úp không được truy vấn face metadata và không được lộ ID/tên/chất/số; token chỉ sống trong một request.
- Với native dialog, chỉ các QML/model đã whitelist được chuyển thành panel React; payload cyclic/oversized/unknown component phải bị từ chối an toàn.
- Bằng chứng hosted phải ghi command, request ID đã sanitize, kết quả server tiếp tục xử lý và cleanup; fixture/local PASS chỉ chứng minh bridge/parser.

## Hàng đợi sau CP19

1. **Đã đóng targeted evidence live:** baseline room lifecycle, card-chosen lá úp, Poxi nhiều lá và CardsAndChoice (`shangyi`); còn cancellation/expiry/reconnect/caller matrix cần lịch live riêng.
2. Chạy các luồng gameplay thực: cứu Đào normal và phân biệt Battle Royal, quyết chiến/lập quốc, view-as; đối chiếu payload wire và trạng thái UI.
3. Chạy hosted native dialogs theo caller có thật: ArrangeCards, MoveCardInBoard, ChooseSkill, generals+choice, card names, KnownBoth.
4. **Code đã đóng CP18:** sửa các chuỗi Việt hóa raw như `祸水`/`礼下` theo `package + skill + context`, đồng thời không đổi ID wire; phần còn lại là đối chiếu caller/live evidence.
5. **Code đã đóng CP18:** rà prompt/choice/log/result/reconnect/error state ở 320, 390, landscape và 1280 px bằng browser fixture; hosted/device cảm ứng vẫn mở.

## Trạng thái hosted QA ngày 12/10/2026

- `game/web/scripts/multiplayer-e2e/run.ts` đã có cấu hình caller thật theo pack: `card-chosen` giữ `hegemony_standard` để nhắm Bàng Đức/`jianchu`, `cards-and-choice` giữ `formation` để nhắm Tưởng Khâm/`shangyi`, còn `poxi` giữ `tenyear_heg` để nhắm Đặng Chi/`weimeng`. Pool được áp dụng sau khi đặt room 2 ghế; nếu server không offer general mục tiêu, runner fail rõ ràng thay vì rơi về cặp random.
- Runner ghi command/request ID và reply đã sanitize, cờ `hidden`/`selected-N`/CardsAndChoice, target/active-skill/native-dialog observation; không ghi card payload, raw ID riêng tư hay credential.
- **Evidence hosted hiện tại đều PASS:** baseline `scratch/evidence/cp08-multiplayer-live-1791819087199.json`; card-chosen `scratch/evidence/cp08-card-chosen-multiplayer-live-1791819116929.json`; Poxi `scratch/evidence/cp08-poxi-multiplayer-live-1791819184413.json`; CardsAndChoice `scratch/evidence/cp08-cards-and-choice-multiplayer-live-1791819227037.json`. Cả bốn có `result: PASS`, `errors: []`; ba ca targeted dùng hai tài khoản thật/Chrome 390×844, server C++ tiếp tục đến GameOver/result/lobby/disconnect; không phải bằng chứng thiết bị vật lý.
- Local hiện quan sát lại `scripts/*.test.ts` **105/105**, Lua browser **51/51**, mock **18/18**, PWA offline **PASS**, `room-pools` **PASS**, live-config **2/2**, release fixture **1/1**, smoke/typecheck/build/diff-check **PASS**. Các fixture bao phủ rescue normal/Battle Royal, view-as, founding và Arrange/Move/ChooseSkill/generals+choice/card names/KnownBoth; đây vẫn là local evidence.
- Rescue live bounded chưa đạt: normal 4 ghế không tự vào Battle Royal nhưng chưa có Peach enabled; Battle Royal có banner/kỹ năng `Quyết chiến` nhưng chưa hoàn tất Đào→Rượu→cứu. Founding latest đã offer/chọn được `Giả Nam Phong + Lưu Bị` qua native general dialog, nhưng source pin không phát `AskForChoices` cho nhánh lập quốc; `ld__zhonghui` trước đó tự map `heg_han`. Evidence latest `scratch/evidence/reconnect-failure-1791809018210.json` là FAIL, không dùng làm PASS.
- Rescue/Battle-Royal/founding/view-as và hosted native Arrange/Move/ChooseSkill/generals+choice/card names/KnownBoth vẫn là probe riêng, chưa được gộp vào bốn caller PASS trên. Các failure cũ giữ nguyên để audit; không bypass temp-ban hoặc retry room khi chưa có slot live an toàn.
- Theo yêu cầu vận hành, hosted experimental scenarios đang **khóa mặc định**: scenario chỉ được chạy khi đặt `TQS_LIVE_ENABLE_EXPERIMENTAL_SCENARIOS=1` sau broad deployment. Guard dừng trước khi load live secret/gateway; local fixture không bị khóa. Lý do là FreeKill source pin gọi `temporarilyBan` cho runner/offline khi room còn sống, sau đó `UserManager` chặn IP trước auth; đây là anti-abuse của server, chưa phải lỗi chứng minh từ card-selection/Poxi.

Chi tiết callsite, line number và count được sinh bên dưới bằng script inventory.
