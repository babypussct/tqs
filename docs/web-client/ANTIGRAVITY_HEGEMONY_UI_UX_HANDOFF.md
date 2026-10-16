# Handoff plan — hoàn thiện UI/UX Web/Mobile Quốc Chiến

> Tài liệu này là một kế hoạch triển khai độc lập để giao thủ công cho Antigravity 3.8 Flash High.
> Phạm vi chính là UI/UX và các thay đổi state/contract tối thiểu cần thiết để UI hoạt động đúng.
> Không mở rộng thành việc port toàn bộ FreeKill Qt/QML và không thay thế luật FreeKill C++/Lua.

## 1. Mục tiêu bàn giao

Hoàn thiện web/mobile client dành riêng cho `new_heg_mode` trên nền code hiện tại:

- React + TypeScript + Zustand.
- Wasmoon Lua và gateway hiện tại.
- FreeKill C++/Lua là nguồn sự thật duy nhất của luật.
- 14 package đang được pin trong runtime hiện hành.
- Giao diện tiếng Việt, touch-first, ưu tiên điện thoại.
- Hỗ trợ portrait và landscape; desktop browser dùng để QA/debug.

Kết quả cần đạt là một client Quốc Chiến có thể dùng thực tế trong các flow đã được scope, không bị kẹt ở prompt/dialog, không lộ private information và không làm người chơi phải cuộn một trang quá dài để thao tác.

Đây là bản mobile reinterpretation có semantics tương thích FreeKill, không phải bản sao pixel-perfect của Qt/QML.

## 2. Quy tắc bắt buộc

### Được phép

- Sửa React/TypeScript/CSS và các test UI liên quan.
- Thêm component, typed UI schema, state selector hoặc helper phục vụ UI.
- Sửa reducer/state projection khi cần để render đúng state authoritative.
- Thêm screenshot/evidence và test regression.
- Refactor nhỏ có phạm vi rõ, có test bảo vệ.

### Không được phép

- Không port hoặc viết lại luật damage, reveal, kingdom, card effect, winner, rescue trong TypeScript.
- Không sửa source Lua/C++/package để làm một UI test giả lập thành công.
- Không auto-select, auto-reply hoặc bỏ qua prompt để vượt qua test.
- Không chạy arbitrary QML, arbitrary Lua hoặc raw HTML từ payload server.
- Không lộ raw private card ID, hidden general hoặc thông tin đối thủ vào public DOM/state.
- Không thay đổi package pin, runtime identity, gateway contract hoặc deployment.
- Không sửa/xóa/reset/clean các thay đổi có sẵn của người dùng hoặc phiên khác.
- Không deploy production.
- Không commit thay người điều phối nếu chưa được yêu cầu.

## 3. Tài liệu và source phải đọc trước khi sửa

Đọc toàn bộ các tài liệu sau trước khi bắt đầu:

1. [`AGENTS.md`](../../AGENTS.md)
2. [`CODEX_STATE.md`](../CODEX_STATE.md)
3. [`CODEX_PLAN.md`](../CODEX_PLAN.md)
4. [`MOBILE_PLAYABLE_MASTER_PLAN.md`](./MOBILE_PLAYABLE_MASTER_PLAN.md)
5. [`QUOC_CHIEN_RULE_AUDIT.md`](./QUOC_CHIEN_RULE_AUDIT.md)
6. [`WEB_CLIENT_PLAN.md`](./WEB_CLIENT_PLAN.md)

Đọc các entry point hiện tại:

- [`App.tsx`](../../game/web/src/App.tsx)
- [`LobbyScreen.tsx`](../../game/web/src/LobbyScreen.tsx)
- [`GameBoardScreen.tsx`](../../game/web/src/GameBoardScreen.tsx)
- [`PlayerPhotoPanel.tsx`](../../game/web/src/PlayerPhotoPanel.tsx)
- [`GameplayControls.tsx`](../../game/web/src/GameplayControls.tsx)
- [`NativeDialogPanel.tsx`](../../game/web/src/NativeDialogPanel.tsx)
- [`HandCardItem.tsx`](../../game/web/src/HandCardItem.tsx)
- [`gameStore.ts`](../../game/web/src/store/gameStore.ts)
- [`boardState.ts`](../../game/web/src/store/boardState.ts)
- [`gameplayState.ts`](../../game/web/src/store/gameplayState.ts)
- [`connection.ts`](../../game/web/src/engine/connection.ts)
- [`nativeDialogs.ts`](../../game/web/src/engine/nativeDialogs.ts)
- [`gameplayInteraction.ts`](../../game/web/src/engine/gameplayInteraction.ts)
- [`styles.css`](../../game/web/src/styles.css)

Đối chiếu khi cần với các component gốc:

- [`RoomBase.qml`](../../runtime/packages/freekill-core/LunarLtk/Pages/RoomBase.qml)
- [`Room.qml`](../../runtime/packages/freekill-core/LunarLtk/Pages/Room.qml)
- [`Dashboard.qml`](../../runtime/packages/freekill-core/LunarLtk/Components/Dashboard.qml)
- [`Photo.qml`](../../runtime/packages/freekill-core/LunarLtk/Components/Photo.qml)
- [`EquipArea.qml`](../../runtime/packages/freekill-core/LunarLtk/Components/Photo/EquipArea.qml)
- [`MarkArea.qml`](../../runtime/packages/freekill-core/LunarLtk/Components/Photo/MarkArea.qml)
- [`Lobby.qml`](../../runtime/packages/freekill-core/Fk/Pages/Lobby/Lobby.qml)
- [`CreateRoom.qml`](../../runtime/packages/freekill-core/Fk/Pages/Lobby/CreateRoom.qml)
- [`WaitingRoom.qml`](../../runtime/packages/freekill-core/Fk/Pages/Common/WaitingRoom.qml)

## 4. Trạng thái hiện tại cần giữ nguyên

Các phần sau đã có bằng chứng hoặc contract hiện hành; không được làm regress:

- Browser E2E hiện có.
- Real Lua browser E2E hiện có.
- Hidden skill projection/prelight/reveal lifecycle.
- Public/private board projection.
- Main/deputy hidden general handling.
- Card display và tooltip baseline.
- Native dialog parser whitelist.
- Request expiry và duplicate-reply protection.
- Vietnamese catalog chính thức.
- Gateway/runtime/package identity hiện hành.

Lưu ý về evidence:

- `SOURCE` chỉ chứng minh code/contract tồn tại.
- `LOCAL` chỉ chứng minh fixture hoặc browser local.
- `NATIVE-LOCAL` là browser → gateway → FreeKill C++ thật trong runtime cô lập.
- `LIVE` là candidate/hosted.
- `BOUNDED` chỉ có nghĩa là scenario cụ thể đã chạy.

Không được dùng test local hoặc số lượng file để tuyên bố full rule parity.

## 5. Thứ tự thực hiện

Thực hiện theo thứ tự dưới đây. Không bắt đầu bằng việc polish màu sắc nếu prompt/gameplay layout còn có thể bị thay đổi.

```text
M0 baseline + UI contract
        ↓
M1 mobile board shell + deterministic seats
        ↓
M2 player/hand/skill/target presentation
        ↓
M3 request/dialog UX
        ↓
M4 lobby/create-room/waiting-room UX
        ↓
M5 performance/accessibility/visual polish
        ↓
M6 regression + screenshot evidence + handoff
```

Các mốc M1, M2 và M3 có thể triển khai song song sau khi M0 hoàn tất, nhưng không được để mỗi mốc tự định nghĩa một prompt/state contract khác nhau.

## 6. M0 — Baseline và UI contract

### Việc cần làm

- Chạy baseline:

  ```bash
  git status --short
  git log -1 --oneline
  npm run codex:resume
  npm --prefix game/web run typecheck
  npm --prefix game/web run test:store
  npm --prefix game/web run test:e2e
  npm --prefix game/web run test:e2e:lua
  npm --prefix game/web run test:native-dialogs
  npm --prefix game/web run test:card-display
  ```

- Ghi lại baseline PASS/FAIL trước khi sửa.
- Chốt viewport QA:
  - 360×800 portrait.
  - 390×844 portrait.
  - 412×915 portrait.
  - 768×1024 tablet/portrait.
  - 1280×720 landscape/desktop.
- Chốt seat profiles: 2, 4, 6, 8; thêm 10 chỉ khi mode hiện tại thực sự cho phép.
- Liệt kê các command UI đã có renderer và các command hiện đang rơi vào fallback.
- Không thay đổi backend để giảm số fallback.

### Deliverable

Một ghi chú ngắn trong report bàn giao:

- baseline commands.
- file hiện sẽ sửa.
- command/request hiện bị fallback.
- viewport/seat profile sẽ chứng minh.
- các thay đổi không nằm trong scope.

## 7. M1 — Mobile board shell và deterministic seat layout

### Mục tiêu

Thay bố cục board phụ thuộc ellipse/scroll dài bằng các layout deterministic dành cho Quốc Chiến.

### Portrait layout

Ưu tiên thứ tự vùng:

1. Header nhỏ: connection, turn/prompt status, log toggle.
2. Opponent compact rail.
3. Center table: draw pile, processing, discard, current effect.
4. Prompt/target/timer layer.
5. Fixed action bar.
6. Self photo + skill dock.
7. Horizontal hand-card rail.

Không để action bar bị đẩy khỏi viewport chỉ vì hand card hoặc log dài.

### Landscape layout

- Board chiếm phần lớn viewport.
- Self dashboard cố định ở đáy.
- Hand card chạy ngang.
- Skill dock không che table center.
- Log mở thành drawer bên phải hoặc panel có thể đóng.

### Seat map

Tạo một helper/layout map có test cho:

- 2 người: đối thủ trên, self dưới.
- 4 người: hai bên và phía trên.
- 6 người: hai bên + hàng trên.
- 8 người: sơ đồ ổn định gần native FreeKill.
- 10 người: layout compact riêng nếu cần.

Mỗi seat phải giữ đồng thời:

- server player id.
- server seat number.
- relative visual index.
- self/opponent state.
- targetable/selected/active state.
- privacy state.

Không dùng vị trí visual để suy ra server seat hoặc player id.

### Acceptance criteria

- Không clipping ở các viewport M0.
- Self luôn ở vùng dễ thao tác.
- Target overlay không bị che bởi log/hand/action bar.
- Không có horizontal overflow ngoài hand rail có chủ đích.
- Board đọc được ở 8 người.
- Layout không phụ thuộc vào emoji hoặc ký tự text để giữ kích thước.

## 8. M2 — Player panel, hand, skill và target UX

### Player panel

Giữ hoặc hoàn thiện các state:

- Main/deputy portrait.
- Hidden/unrevealed general.
- Kingdom/seat/name.
- HP/shield.
- Hand count.
- Equipment 5 slot.
- Delayed trick.
- Mark.
- Chained/face-up/drunk/dying/dead.
- Active/selected/targetable.
- Reveal transition.

Không dùng emoji làm icon production cho equipment/skill/action. Dùng asset/icon class có kích thước và contrast ổn định.

### Hand card

- Card fan/rail có snap và scroll trên mobile.
- Selected/disabled/targeted state rõ ràng.
- Tooltip hoạt động bằng tap/long press, không chỉ hover.
- Có card count/selection count khi prompt yêu cầu.
- Không render toàn bộ danh sách lại khi chỉ đổi selection một card.

### Skill dock

Tách rõ:

- Fake hidden skill.
- Regular passive skill.
- Active skill.
- Prelighted skill.
- Disabled skill.
- Skill đang được Lua yêu cầu invoke.

Không tự cho regular skill hoạt động nếu Lua chưa phát request hợp lệ.

### Target mode

- Có target overlay riêng.
- Hiển thị target hợp lệ/không hợp lệ.
- Có cách hủy target mode rõ ràng.
- Có feedback sau khi server nhận action.
- Không gửi target nếu request đã hết hạn hoặc request id đã đổi.

## 9. M3 — Request và dialog UX

### Dialog registry cần có renderer hoặc adapter

- `AskForSkillInvoke`.
- `AskForChoices`.
- `AskForOptions`.
- `AskForCardChosen`.
- `AskForPoxi`.
- `AskForCardsAndChoice`.
- `AskForArrangeCards`.
- `AskForAG`.
- `AskForMoveCardInBoard`.
- `AskForGeneral`.
- `ChooseSkill`.
- `KnownBoth`.
- `ChooseCardNames`.
- Initial general selection.
- GameOver/result.
- `CustomDialog` trong phạm vi schema whitelist.

### Mỗi dialog phải xử lý

- Render payload hợp lệ.
- Invalid payload.
- Success response.
- Cancel nếu server hỗ trợ.
- Expiry/timeout.
- Duplicate click.
- Reconnect.
- Cleanup khi `CancelRequest`, `StartGame`, `GameOver`, `EnterLobby`.
- Mobile portrait/landscape.

### Fallback

Fallback chỉ được dùng ngoài canonical scenario và phải:

- Nói rõ command chưa được hỗ trợ.
- Không auto-reply.
- Không làm UI im lặng chờ vô hạn.
- Ghi diagnostic command/payload shape nhưng không ghi private data.

Nếu command cần cho Quốc Chiến release mà đang fallback, phải thêm adapter trước khi đánh dấu hoàn thành.

## 10. M4 — Lobby, Create Room và Waiting Room

### Lobby

Giữ focus riêng cho Quốc Chiến:

- Room list.
- Mode compatibility.
- Capacity/open seats.
- Password.
- Refresh.
- Pool summary.
- Create room.
- Server status.

MOTD/chat/replay/more-pages chỉ làm khi contract backend đã rõ và không ảnh hưởng gameplay P0.

### Create Room

Thiết kế thành wizard/accordion mobile:

1. Tên phòng.
2. Số người.
3. Timeout.
4. Mode Quốc Chiến.
5. Pool tướng.
6. Pool bài.
7. Ban general.
8. Mode-specific settings.
9. Review và tạo.

Không hiển thị option mà `GameAdapter` hoặc server chưa thật sự xử lý.

### Waiting Room

- Hiển thị đủ ghế và ghế trống.
- Hiển thị owner/bot/self.
- Ready chỉ hiện khi state cho phép.
- Start chỉ enable khi phòng đủ người và tất cả người không phải owner đã ready theo semantics native.
- Add bot chỉ khi còn ghế và server cho phép.
- Hiển thị lý do start đang disabled.
- Giữ leave room rõ ràng.
- Nếu observer chưa hỗ trợ, không render control giả; ghi rõ deferred.

Không để UI cho phép người dùng bấm start sớm rồi chờ server từ chối trong im lặng.

## 11. M5 — Performance, accessibility và visual polish

### Performance

- Dùng Zustand selector hẹp.
- `React.memo` cho seat/card/skill item.
- Tách timer/log khỏi board render.
- Dùng CSS transform cho animation vị trí.
- Virtualize log/hand nếu cần.
- Lazy-load tướng/card asset.
- Không preload toàn bộ asset catalogue ở first paint.

### Touch/accessibility

- Target cảm ứng tối thiểu khoảng 44px.
- Có contrast cho selected/disabled/target.
- Có aria label cho card, skill, seat và action.
- Long press không phải cách duy nhất để xem chi tiết.
- Dialog có focus order.
- Không để safe-area che nút.
- Không dùng hover-only behavior.

### Visual

- Giữ theme dark green/gold/classical hiện tại nếu không có lý do UX để đổi.
- Chuẩn hóa token màu, border, shadow, radius, typography.
- Thay emoji bằng asset/icon production.
- Animation chỉ dùng khi giúp hiểu state: reveal, damage, heal, target, card movement.
- Không làm animation che prompt hoặc làm chậm thao tác.

## 12. M6 — Test và bằng chứng bắt buộc

Sau khi sửa, chạy tối thiểu:

```bash
npm --prefix game/web run typecheck
npm --prefix game/web run test:store
npm --prefix game/web run test:gameplay
npm --prefix game/web run test:native-dialogs
npm --prefix game/web run test:card-display
npm --prefix game/web run test:e2e
npm --prefix game/web run test:e2e:lua
npm --prefix game/web run build
```

Nếu thay đổi request/hidden skill/board privacy, chạy thêm các audit/test liên quan trong `game/web/package.json`.

Phải tạo evidence cho:

- 390×844 portrait lobby.
- 390×844 portrait waiting room.
- 390×844 portrait board với prompt.
- 390×844 portrait board với target overlay.
- 1280×720 landscape board.
- 2 người.
- 4 người.
- 8 người.
- Hidden main/deputy.
- Card selection.
- Skill invoke.
- Dialog cancel/expiry nếu có.

Ảnh screenshot chỉ là evidence visual; không dùng screenshot để thay thế state/server assertion.

## 13. Definition of Done

Agent chỉ được báo hoàn thành khi tất cả điều kiện sau có bằng chứng:

- [ ] Không có code thay đổi luật FreeKill trong TypeScript.
- [ ] Không có private card/general leak trong board DOM/public state.
- [ ] Typecheck/build PASS.
- [ ] Test hiện hành không regress.
- [ ] Board portrait/landscape không clipping ở viewport đã chốt.
- [ ] Seat layout deterministic cho profile đã scope.
- [ ] Prompt/dialog P0 không fallback trong canonical scenarios.
- [ ] Expiry/cancel/reconnect không để stale UI.
- [ ] Waiting room không cho affordance sai về ready/start.
- [ ] Lobby/create room hiển thị đúng server-owned state.
- [ ] Equipment/action icon không còn phụ thuộc emoji production.
- [ ] Screenshot evidence đã lưu ở đường dẫn rõ ràng.
- [ ] Report liệt kê mọi file đã sửa.
- [ ] Report liệt kê test command và kết quả thật.
- [ ] Report liệt kê remaining issues, không ghi chung chung “đã hoàn thiện”.

## 14. Mẫu báo cáo bàn giao lại

```text
UI/UX Quốc Chiến handoff report

Baseline:
- branch/HEAD:
- baseline test:

Implemented:
- [file] — [thay đổi]
- [file] — [thay đổi]

Behavioral changes:
- [request/state/layout]

Visual evidence:
- [absolute screenshot path] — [viewport/scenario]

Tests:
- command: PASS/FAIL
- command: PASS/FAIL

Known limitations:
- [issue + reason + next action]

Not changed:
- FreeKill Lua/C++ rules.
- Package pin/runtime identity.
- Production/deployment.
```

## 15. Handoff boundary sau khi agent hoàn tất

Agent UI/UX chỉ bàn giao code và evidence về worktree. Không tự đánh dấu `PLAYABLE_MOBILE`, không tự deploy production và không tự đóng exhaustive rule/effect matrix.

Sau khi nhận lại worktree, người điều phối sẽ:

1. Review diff độc lập.
2. Kiểm tra mọi thay đổi state/contract có giữ privacy và Lua authority không.
3. Chạy lại test trong checkout điều phối.
4. Kiểm tra screenshot trên các viewport mục tiêu.
5. Đối chiếu `CODEX_PLAN.md` và `CODEX_STATE.md`.
6. Chỉ sau đó mới quyết định merge, tiếp tục sửa hoặc mở live smoke test.
