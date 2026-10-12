# CP17 — đối chiếu request thực tế và renderer

Artifact này được sinh bằng `node scripts/cp17-request-inventory.mjs` từ snapshot runtime mà candidate CP16 đã deploy. Nó là inventory source-level: callsite cho biết package có thể phát request, còn cột evidence chỉ được đánh dấu theo bằng chứng test/live đã quan sát; callsite không tự biến thành bằng chứng live. Các dòng AI/parser helper được giữ ở phần chi tiết nhưng tách khỏi số `interactive callers`.

## Cách tái tạo

```bash
node scripts/cp17-request-inventory.mjs \
  scratch/deployments/cp16-candidate/release/runtime \
  > /tmp/cp17-request-inventory.md
```

Lệnh trên xuất bảng và line number đầy đủ ra file tạm để review; phần tóm tắt/queue ở tài liệu này được giữ ổn định khi chỉ đổi số lượng callsite. Snapshot CP16 hiện có 806 file Lua: `freekill-core` 305, `hegemony` 477, `utility` 24.

## Kết luận ưu tiên

| Ưu tiên | Request thực tế | Caller tương tác | Renderer hiện có | Bằng chứng hiện tại | Việc cần đóng |
| --- | --- | ---: | --- | --- | --- |
| P0 | `AskForCardChosen` | 63 | `CardSelectionPanel` một lá | Live một phần: Bàng Đức/jianchu chọn trang bị công khai | Chọn lá úp, lấy/bỏ bài và privacy trên server thật |
| P0 | `AskForPoxi` | 10 (18 cả AI/helper) | `CardSelectionPanel` nhiều lá | Lua/Wasmoon fixture PASS, chưa hosted | Ván nhiều lá thật, reply CBOR array đúng request ID, cancel/expiry/reconnect |
| P0 | `AskForCardsAndChoice` | 2 | `CardsAndChoicePanel` | Lua/Wasmoon fixture PASS, chưa hosted | `zongpei`/`shangyi`: xem/chọn bài và choice thật |
| P0 | `AskForUseActiveSkill` | 24 | `GameBoardScreen` + Lua scene | Fixture rescue/battle-royal/view-as PASS, live matrix mở | Cứu Đào hợp lệ, quyết chiến/lập quốc, view-as; không suy diễn luật từ UI |
| P1 | `AskForUseCard` | 9 | `GameBoardScreen` + Lua scene | Generic gameplay fixture/live ván bot | Response-card/Thiểm/Đào hợp lệ và view-as |
| P0 | `AskForArrangeCards` | 3 | `NativeDialogPanel` arrange | Fixture PASS, chưa hosted | `xunxun`/`shelie` hoặc caller tương đương trên ván thật |
| P0 | `AskForMoveCardInBoard` | 3 | `NativeDialogPanel` boardMove | Fixture PASS, chưa hosted | `mouduan`/`qiaobian`/`yongjin` trên ván thật |
| P0 | `CustomDialog` | 6 | `NativeDialogPanel` QML whitelist | Fixture PASS, initial-general live riêng | ChooseSkill, generals+choice, card names, KnownBoth trên ván thật |
| P1 | `AskForChoices` | 91 | `ChoicePanel` | Fixture PASS, đã gặp choice/reveal trong live; rule matrix mở | Rà các choice từ rescue/duel/lập quốc và cancel/expiry |
| P1 | `AskForSkillInvoke` | 0 direct | `SkillInvokePanel` | Fixture PASS; caller trực tiếp do core parser/client định nghĩa | Xác nhận trong hosted skill flow phù hợp |
| P2 | `AskForAG` | 1 | `NativeDialogPanel` AG | Fixture PASS; có caller trong core standard, chưa hosted | Không ưu tiên trước request có caller live gap lớn hơn; giữ regression fixture |

## Bất biến nghiệm thu cho mỗi ca

- Lua là nguồn sự thật cho `pattern`, min/max, feasible/targets và `view_as`; React không tự tái lập luật.
- Một request chỉ được trả lời một lần bằng CBOR đúng kiểu và đúng `requestId`; không gửi reply stale/duplicate sau cancel, timeout, reconnect hoặc request bị thay thế.
- Bài úp không được truy vấn face metadata và không được lộ ID/tên/chất/số; token chỉ sống trong một request.
- Với native dialog, chỉ các QML/model đã whitelist được chuyển thành panel React; payload cyclic/oversized/unknown component phải bị từ chối an toàn.
- Bằng chứng hosted phải ghi command, request ID đã sanitize, kết quả server tiếp tục xử lý và cleanup; fixture/local PASS chỉ chứng minh bridge/parser.

## Hàng đợi CP17

1. Đóng evidence live cho card-chosen lá úp và Poxi nhiều lá; sau đó CardsAndChoice (`zongpei`/`shangyi`).
2. Chạy các luồng gameplay thực: cứu Đào normal và phân biệt Battle Royal, quyết chiến/lập quốc, view-as; đối chiếu payload wire và trạng thái UI.
3. Chạy hosted native dialogs theo caller có thật: ArrangeCards, MoveCardInBoard, ChooseSkill, generals+choice, card names, KnownBoth.
4. Sửa các chuỗi Việt hóa raw như `祸水`/`礼下` theo `package + skill + context`, đồng thời không đổi ID wire.
5. Rà prompt/choice/log/result/reconnect/error state ở 320, 390 và 1280 px; giữ raw internal ID ngoài vùng debug.

Chi tiết callsite, line number và count được sinh bên dưới bằng script inventory.
