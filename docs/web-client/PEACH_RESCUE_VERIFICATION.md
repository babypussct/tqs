# Cứu Đào và luật Quốc Chiến — checkpoint 11/10/2026

Phạm vi đã kiểm chứng: Chrome 390×844, Wasmoon chạy bộ Lua pin hiện tại (808 file), production React/GameConnection; gói tin máy chủ là fixture cục bộ. Chưa nghiệm thu các ca cứu Đào/quyết chiến trong ván FreeKill thật.

## Luật và gói tin native

- `freekill-core/standard/aux_skills_dir/game_rule.lua` hỏi cứu bằng `AskForUseCard`: `{skillName, pattern, prompt, cancelable, extra_data, disabledSkillNames}`. Người khác chỉ dùng `peach`; bản thân dùng `peach,analeptic`. `extra_data` chứa `analepticRecover=true`, `must_targets={dyingId}`, `fix_targets={dyingId}`. HP -1 cần hồi hai lần để lên 1.
- `ltk/core/request_type/use_card.lua` và `ltk/core/card.lua` giữ mục tiêu cố định trong Lua. Với Đào thật, reply native là `{card=cardId, targets={}}`: client không chọn Photo; server áp dụng `fix_targets` và game_rule gán người đang hấp hối vào `tos`. Không tự thêm target hay sửa bytes reply trong JavaScript.
- `hegemony/pkg/gamemodes/skills/new_battle_royal.lua`: Đào thường bị prohibitUse và có kỹ năng view-as thành Rượu. Rượu tự cứu, không cứu người khác. Bản cũ `battle_royal.lua` chuyển Đào thành Sát/Né. Predicate loại trừ bài chuyển hóa có skillNames và mark `_heg__BattleRoyalMode_ignore` khác 0. Không cấm toàn bộ bài có trueName peach trong JavaScript.
- `companion_skill.lua`: dấu Châu Liên Bích Hợp cho phép dùng Đào ảo; ca này vẫn hợp lệ khi Đào thật trên tay bị quyết chiến cấm.
- `hegemony/util.lua:176` chọn quốc hiệu từ `wildKingdoms`, bỏ quốc hiệu đã có người dùng; một số tướng có quốc hiệu chỉ định. `wildChooseKingdom` cập nhật role và công khai role_shown. `getKingdom` lấy role nếu kingdom là wild. Web dùng hàm này để hiển thị quốc hiệu; không sửa luật lập quốc hay điều kiện thắng.

Các đường dẫn Lua trên nằm dưới `scratch/upstream/`; snapshot gateway pin tại `scratch/live-web-test/7017f8e8-f2c2-4365-b7f9-977ccf5c57a0`, MD5 flist `a2a4b0af428f971c2642f11bd4aef162`.

## Thay đổi client

- Bridge bổ sung disabledReason chỉ khi predicate của kỹ năng quyết chiến native thực sự cấm lá Đào đang disabled; cập nhật cả scene ban đầu và delta, xóa lý do khi bài hợp lệ trở lại. Không đổi enabled/selected/reply.
- Prompt cứu người khác, tự cứu, mục tiêu cố định, hai chế độ quyết chiến và 12 quốc hiệu được Việt hóa. Sửa key marks theo Lua thật: `@!!vanguard`, `@!!yinyangfish`, `@!!companion`, `@!!wild`, `@[:]BattleRoyalDummy`.
- Event VisibleKingdom chỉ chứa tên thế lực do HegUtil tính cho Self hoặc player có role_shown. Reducer từ chối tên của ghế lạ/đối thủ chưa công khai và xóa khi bị ẩn lại; không đưa role riêng của đối thủ vào store.

## Bằng chứng đã quan sát

`npm run test:e2e:lua` **33/33 PASS**. Các ca thêm mới gồm: cứu đối thủ; không tự hồi HP trước event server; HP -1→0→1 qua hai request; quyết chiến mới/cũ và ignore mark; Hủy không mất bài; chuyển Đào thành Rượu tự cứu; Đào ảo Châu Liên Bích Hợp; chọn quốc hiệu giữ wire ID; tên quốc hiệu hiển thị theo Lua và giữ riêng tư khi chưa công khai. Toàn bộ ca trước vẫn PASS, luaErrors rỗng.

`npm run test:gameplay` **14/14**, `npm run test:store` **18/18**, `npm run test:e2e` **17/17**, smoke, build và strict typecheck harness/runner đều PASS. Build vẫn có cảnh báo Wasmoon/module externalization và bundle lớn (~750.65 kB JS, gzip ~223.74 kB).

Log và ảnh đã xem trong `scratch/evidence/`: `game-03c-lua-test-2026-10-11.txt`, `peach-rescue-lua-fixture-2026-10-11.png`, `battle-royal-peach-lua-fixture-2026-10-11.png`, `wild-kingdom-lua-fixture-2026-10-11.png`. Các ảnh là fixture, không phải bằng chứng ván thật hay điện thoại vật lý.

## Còn cần nghiệm thu

Cứu Đào/quyết chiến và lập quốc trong ván server thật; đối chiếu request/reply với trace đầy đủ. Không login runner cùng account đang chơi hoặc reload/disconnect trong ván. Bản HTTPS cp01 tiếp tục phục vụ build cũ đóng băng; cp05 là archive local chứa build mới, chưa thay origin public.
