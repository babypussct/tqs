# CP29 — native caller inventory của candidate

Cập nhật 13/10/2026 từ đúng runtime 11 package của candidate:

```text
runtime: scratch/deployments/cp28-hosted-compatible-20261013/release/runtime
Lua files: 4,717
package roots: 11
```

Sinh lại bằng:

```bash
node scripts/cp17-request-inventory.mjs \
  scratch/deployments/cp28-hosted-compatible-20261013/release/runtime \
  > /tmp/cp29-request-inventory.md
```

Gate tự động tương ứng:

```bash
npm run audit:native-callers
```

Gate này fail-closed khi một request family có callsite trong runtime nhưng
thiếu mapping production hoặc thiếu fixture local đã đăng ký. Lượt CP30 chạy
trên đúng candidate runtime: **4.717 Lua files / 16 request families / PASS**;
count callsite khớp inventory bên dưới. Đây là gate source/local, không phải
bằng chứng semantic live trên C++.

Inventory đếm callsite Lua, không coi số lượng callsite là bằng chứng luật đã chạy trên C++ thật. Các request vẫn phải đi qua Lua để quyết định `pattern`, min/max, target, `view_as`, cancellation và reply CBOR.

| Ưu tiên | Lua method | Wire request | Renderer production | Interactive / all | Bằng chứng hiện tại |
| --- | --- | --- | --- | ---: | --- |
| P1 | `askToChoice` | `AskForChoices` | `ChoicePanel` | 649 / 649 | Local renderer + real-Lua fixture PASS; rule-specific hosted còn mở |
| P1 | `askToChoices` | `AskForChoices` | `ChoicePanel` | 39 / 39 | Local renderer + real-Lua fixture PASS; rule-specific hosted còn mở |
| P0 | `askToChooseCard` | `AskForCardChosen` | `CardSelectionPanel` single | 457 / 457 | Local PASS; Bàng Đức/`jianchu` hidden-card hosted targeted PASS trước đó |
| P0 | `askToChooseCards` | `AskForPoxi` | `CardSelectionPanel` multi | 129 / 149 | Local PASS; Đặng Chi/`weimeng` hosted targeted PASS trước đó |
| P0 | `askToChooseCardsAndChoice` | `AskForCardsAndChoice` | `CardsAndChoicePanel` | 12 / 12 | Local PASS; Tưởng Khâm/`shangyi` hosted targeted PASS trước đó |
| P0 | `askToChooseCardsAndPlayers` | `AskForUseActiveSkill` | `GameBoardScreen` + Lua scene | 126 / 126 | Local PASS; rescue/duel/founding live semantic còn mở |
| P0 | `askToUseActiveSkill` | `AskForUseActiveSkill` | `GameBoardScreen` + Lua scene | 166 / 166 | Local PASS; view-as/Battle-Royal/founding live semantic còn mở |
| P1 | `askToUseCard` | `AskForUseCard` | `GameBoardScreen` + Lua scene | 73 / 73 | Local PASS; normal rescue hosted PASS, Battle-Royal còn mở |
| P0 | `askToChooseToMoveCardInBoard` | `AskForMoveCardInBoard` | `NativeDialogPanel` boardMove | 23 / 23 | Local PASS; chưa có hosted caller evidence |
| P0 | `askToArrangeCards` | `AskForArrangeCards` | `NativeDialogPanel` arrange | 46 / 46 | Local PASS; chưa có hosted caller evidence |
| P2 | `askToAG` | `AskForAG` | `NativeDialogPanel` AG | 2 / 2 | Local PASS; chưa có hosted caller evidence |
| P0 | `askToCustomDialog` | `CustomDialog` | `NativeDialogPanel` allowlist | 15 / 15 | Local PASS; hosted native-dialog matrix còn mở |
| P0 | `askToChooseSkills` | `CustomDialog` | `NativeDialogPanel` skills | 10 / 10 | Local PASS; chưa có hosted caller evidence |
| P0 | `askToChooseGeneralsAndChoice` | `CustomDialog` | `NativeDialogPanel` generals+choice | 9 / 9 | Local PASS; initial-general live là caller riêng |
| P0 | `askForChooseCardNames` | `CustomDialog` | `NativeDialogPanel` cardNames | 18 / 18 | Local PASS; chưa có hosted caller evidence |
| P1 | `askForSkillInvoke` | `AskForSkillInvoke` | `SkillInvokePanel` | 0 / 1 | Core parser/client-defined; `ex__fankui` prompt `nil` real-Lua PASS |

## Coverage thực tế

- Local real-Lua/React hiện **53/53 PASS**, bao gồm `AskForSkillInvoke`, AG, ArrangeCards, KnownBoth, ChooseSkill, ChooseGeneralsAndChoice, MoveCardInBoard, CardChosen, Poxi, CardsAndChoice, rescue thường, Battle-Royal view-as fixture, founding fixture và Reconnect.
- Hosted candidate CP28 có baseline hai account **PASS** tới GameOver/result/lobby/disconnect; evidence [`cp28-multiplayer-live-1791833242992.json`](../../scratch/evidence/cp28-multiplayer-live-1791833242992.json).
- Hosted targeted matrix trước đó có `AskForCardChosen`, `AskForPoxi`, `AskForCardsAndChoice` **4/4 PASS**; không gộp các caller khác vào kết quả này.
- Battle-Royal rescue→view-as và founding kingdom choice đã có failure evidence có kiểm soát trên native C++ hiện tại; không đổi thành PASS từ fixture và không retry khi chưa có lịch vận hành an toàn.

## Kết luận gate

Inventory này chứng minh mọi nhóm request có renderer production tương ứng và các payload/lifecycle path đã có local regression. Nó **không** chứng minh mọi skill semantic đều đã được kích hoạt trên C++ thật trong mọi điều kiện bàn. Gate full native caller/rules vẫn `PENDING` cho đến khi có server/package hỗ trợ và evidence live cho các caller còn thiếu.
