# Kế hoạch nghiệm thu đồng bộ Quốc Chiến ngày 27/11/2026

Phạm vi là `new_heg_mode` của TQSVN, tập trung vào Thành Lược `ld__chenglue`, Ký Ly `ld__jilix` và các chênh lệch FreeKill Core có ảnh hưởng đến luật, request/reply hoặc bí mật thông tin. Dùng pin Hegemony `e8d93acd34a357f96b0105aef7d661708c211626` và FreeKill Core `3c40e0f8dc54608a3b862c0cfcad80e5e61f5e02`. Phạm vi triển khai kế tiếp là QA cô lập. Phát hành production và thay đổi TQSShop nằm ngoài kế hoạch này. [Pin/overlay native](../../deploy/freekill-native/upstream-baseline.env) · [Bàn giao](../CODEX_STATE.md)

## 1. Trạng thái xác minh

| Hạng mục | Kết quả ngày 27/11 | Bằng chứng |
| --- | --- | --- |
| Gate baseline chạy lại | **PASS** 14/14 pin, 14/14 vá native, 1/1 vá source, 520 Lua Hegemony, 3 ngoại lệ có hash, 1 file luật Core. | [`check-upstream-baseline.mjs`](../../game/web/scripts/check-upstream-baseline.mjs) |
| Hegemony local, overlay và production | Local có 517/520 file khớp overlay sau chuẩn hóa LF; ba ngoại lệ là `pkg/gamemodes/new_hegemony_mode.lua`, `util.lua` và `utilevent/events/remove_general.lua`. Production và overlay cùng inventory 520 Lua, khác nội dung tại file mode và `pkg/nine_variations/skills/turban_shell_cup.lua`. Pin gốc khác overlay ở 14 file, khác production ở 15 file. | [Overlay 15/11](../../deploy/freekill-native/artifacts/tqsvn-production-bundle-2026-11-15.zip) · [ZIP production lưu cục bộ](../../scratch/evidence/hegemony-runtime-parity-20261127/production.zip) |
| ZIP production so với nguồn staging native | **PASS theo nội dung**. 5.331/5.339 file khớp byte, 8 chỉ khác CRLF/LF, 0 thiếu và 0 delta nội dung. SHA-256 ZIP `96b3025a12448c71718ed11b9bee9803cce7ac0063d9e4417fd248d7faa424bd`, tiền tố SHA-1 `d7492c8447d46062`, MD5 `flist.txt` `2c4e29161bc0b2d37fdc3c0e67486745`. | [Manifest đã lưu](../../scratch/evidence/hegemony-runtime-parity-20261127/manifest.json) · [Nguồn staging](../../scratch/evidence/overbearing-release/candidate-runtime) |
| Probe source chạy lại với Lua 5.4 | **PASS** 11 tình huống Thành Lược và 10 tình huống Ký Ly trên từng nguồn local, archive pin và ZIP production. Các probe gọi callback với room/event giả lập. | [Probe Thành Lược](../../deploy/freekill-native/qa/chenglue-source-probe.lua) · [Probe Ký Ly](../../deploy/freekill-native/qa/jilix-source-probe.lua) |
| Hợp đồng QA server chạy lại | **PASS** 69/69 qua `test:qa-server-contract`. | [Bộ test contract](../../deploy/freekill-native/qa/tqs_qa-catalog.test.mjs) |
| Việt hóa chạy lại | **PASS** 4/4, gồm prompt Thành Lược hiện hành/biến thể cũ và hai choice Ký Ly có placeholder lá bài. | [Test Việt hóa](../../game/web/scripts/hegemony-translation-overlay.test.ts) |
| Phiên native 53293 | **FAIL** ở assertion `Chenglue HP success`. Native sẵn sàng với DB mới và manifest đúng. Hai socket đã qua `CardWireNegotiated` và `PrepareDrawPile`, phép dựng Hỏa Công qua `viewAs` PASS. Client exit 1 khi chờ `GameOver`, hai dấu `stack traceback`, không có `Broken pipe` hoặc lỗi init Lua. Native exit 0 và giải phóng cổng 19681/9000. | [Log 53293](../../scratch/evidence/hegemony-runtime-parity-20261127/skill-parity-native.log) · [Runner socket](../../scratch/evidence/hegemony-runtime-parity-20261127/skill-parity-native.mjs) |
| Lượt chẩn đoán chuẩn hóa reply | **PASS từng nhánh** cho kết toán trực tiếp và hủy chi phí của Thành Lược. Lượt chạy vẫn **FAIL** ở assertion HP của nhánh chặn sát thương. | [Log chẩn đoán đã lọc](../../scratch/evidence/hegemony-runtime-parity-20261127/skill-parity-diagnostics-sanitized.log) |
| Lượt chẩn đoán chuẩn hóa reply và chặn sát thương đúng API | **PASS có giới hạn** trên native với hai socket. Thành Lược PASS kết toán trực tiếp, hủy chi phí và chặn sát thương. Ký Ly PASS hai lựa chọn ở cả hai ô. Hai client nhận `GameOver` do fixture kết thúc, client/native exit 0, không có lỗi worker, cleanup PASS. Fixture gọi `viewAs`/`room:useCard` trực tiếp và dựng tướng Ký Ly bằng `changeHero` nên UI view-as và prelight từ tướng ẩn vẫn cần nghiệm thu. | [Lượt chẩn đoán 5](../../scratch/evidence/hegemony-runtime-parity-20261127/skill-parity-diagnostics-sanitized.log) |
| Sát thương lan truyền | **PASS gameplay bounded**, 3 client, Damage trực tiếp/lan mỗi lần 1 hỏa, đúng lá lộ bị bỏ, lá đối chứng còn tay, tháo xích, 3 GameOver và cleanup. Privacy MoveCards/ShowCard PASS ở ba socket: đúng owner, hai alias outsider khác nhau, đúng lá lộ bị bỏ và thu hồi alias, lá ghế ba không lộ qua các packet đã kiểm. 3 GameOver/EnterLobby, exit 0, worker errors 0, cleanup PASS; reconnect/observer và các kênh khác còn mở. | [Rerun](../../scratch/evidence/hegemony-runtime-parity-20261127/skill-parity-chain-privacy-final.log) |
| Chrome, production OAuth và điện thoại thật | **Chưa chạy cho đợt nghiệm thu này**. | [Quy trình live](LIVE_TESTING.md) |

Tám file lệch newline nằm trong `packages/freekill-core/test/` (`init.lua`, `skills/change_hero.lua`, `skills/cheat.lua`, `skills/control.lua`, `skills/damage_maker.lua`, `skills/test_zhenggong.lua`), `packages/ol/pkg/jsrg/skills/bahu.lua` và `packages/tenyear/pkg/tenyear_token/init.lua`. Đối chiếu nội dung chuẩn hóa LF và MD5 của manifest là hai kiểm tra độc lập. Giữ byte artifact nguồn khi staging và lưu kết quả của cả hai kiểm tra.

## 2. P0 · Tách lỗi fixture, request và luật Thành Lược

Các lượt chẩn đoán tái hiện lỗi tại `Room:askToCards` của Hỏa Công. Client gửi reply chọn lá và `resolveUse` từ chối phần tử `card.subcards` tại `card_wire_request.lua:837/878`. Lượt chạy dừng trước `ShowCard`, prompt chi phí và `DamageInflicted`. Decoder của runner trả CBOR byte string dưới dạng `Buffer`. Runner kiểm tiền tố `h:` bằng `String` rồi đưa `Buffer` gốc vào encoder, khiến token được encode thành map. Trong bản sao tạm, chỉ đổi reply sang chuỗi đã đưa nhánh kết toán trực tiếp và hủy chi phí qua các assertion HP/vùng bài. [Log chẩn đoán đã lọc](../../scratch/evidence/hegemony-runtime-parity-20261127/skill-parity-diagnostics-sanitized.log)

Sau khi sửa reply, nhánh chặn sát thương vẫn FAIL vì hook QA chỉ trả `true` và chưa đặt cờ mà Core dùng để dừng sát thương. Gọi `data:preventDamage()` trong hook `DamageInflicted` đã đưa cả ba nhánh Thành Lược và bốn tổ hợp Ký Ly qua assertion trong lượt kế tiếp. Hai chỉnh sửa chỉ nằm trên bản sao runner/fixture tạm. Đưa cả hai vào bộ QA tái lập được, sau đó chuyển các ca cần chứng minh thao tác người chơi sang đường `PlayCard`.

Các lượt chẩn đoán dùng binary macOS SHA-256 `aa70bc94ac1691ad55f7dfed876b33cf24b81375752d222217eef65ed71190b7` và runtime manifest `2c4e29161bc0b2d37fdc3c0e67486745`. Bản sao runner/fixture tạm được dọn sau mỗi lượt.

1. Khóa baseline bằng MD5 `flist.txt`, SHA-256 binary, source revision, QA fixture/catalog và hash web build khi có Chrome. Dùng staging riêng, Lua 5.4 với `socket`/`lfs`, DB mới, cổng/room quota cô lập và session QA. Kiểm readiness, Card Wire v1 ở cả hai socket và bảo toàn evidence cũ. Runner scratch phụ thuộc binary, SQL bootstrap và Lua rocks từ các phiên trước. Khi chuyển thành bài QA tái lập được, khai báo các đầu vào này hoặc dùng installer QA có kiểm provenance. [Runner staging](../../scratch/evidence/hegemony-runtime-parity-20261127/skill-parity-runtime-qa.py) · [Quy trình live](LIVE_TESTING.md)
2. Chạy đối chứng bằng Hỏa Công vật lý với hand/seat cố định và cùng đường request thật. Sau đó dùng Hỏa Công từ Thành Lược. Một lượt mới phải đi qua `PlayCard` và đường xử lý view-as thật của client/server. Fixture 53293 gọi `viewAs` và `room:useCard` trực tiếp, đủ để vào dispatcher hiệu ứng và chưa kiểm entry point từ UI.
3. Đặt các mốc `PlayCard`/`TargetConfirmed` → chọn lá lộ và nhận reply → `ShowCard`/`fire_attack_show` → chọn và bỏ chi phí → `DamageInflicted` → cập nhật HP → `fk.Damage` và di chuyển lá lộ. Kiểm đếm request theo command, ghế nhận, reply hợp lệ/hủy, số lần kết toán, delta HP và vùng bài trước/sau. Kiểm chính xác lá thông qua assertion trong bộ nhớ, chỉ xuất boolean hoặc bộ đếm. Dùng allowlist context Card Wire và mã case để quyết định reply; runner scratch hiện chọn token `h:` đầu tiên và phân nhánh bằng bộ đếm chung.
4. Ghi kết quả lỗi theo mốc đầu tiên sai. Nếu Hỏa Công thường và view-as đều lệch, ưu tiên fixture, reply và Card Wire. Nếu Hỏa Công thường PASS mà view-as lệch, kiểm subcard, `skillNames`, usage và event cha. Nếu đúng sát thương mà sai bỏ lá, kiểm parent `CardEffect`, `fire_attack_show`, `prohibitDiscard` và `MoveCards`. Chỉ sửa lớp đã được phép thử đối chứng xác định; sau sửa chạy lại đối chứng cùng provenance.
5. Tách từng nhánh thành lượt có seed và bàn bài cố định. Fixture dựng dữ liệu và quan sát, chủ thể thật trả lời request và Core gốc kết toán. Để chặn sát thương, gọi `data:preventDamage()` trong `DamageInflicted` của fixture và xác minh cờ trước khi đổi HP. Điều kiện kết thúc từng lượt là assertion của case, `GameOver` trên cả hai client, client/native exit 0 và cleanup. Log riêng trạng thái cổng, process và thư mục staging. `GameOver` do fixture có thể đóng phép thử giới hạn. Thắng thua tự nhiên cần chứng cứ ván riêng.

**Evidence 11:27:** Mốc 11:27: session 52977 PASS cả 5 lane native độc lập (`tl-physical`, `tl-success`, `tl-cancel`, `tl-prevent`, `chain`), session 80633 PASS regression `playcard` gồm 4 lượt Thành Lược/Hỏa Công và 4 choice Ký Ly. Seed hành động 20261127:4 sau chia bài; bốn lane hai ghế có mặt bài cố định theo tên/chất/số, chain chọn lá grant theo tên/chất từ draw pile, chưa cố định số. Mỗi case 1 TargetConfirmed/1 CardEffecting; DamageInflicted lần lượt 1/1/0/1/2, Damage thành công 1/1/0/0/2. Assert event cha CardEffect, đúng lá lộ/chi phí, HP/vùng bài, chain tháo xích và privacy 3 audience, 2 alias outsider. Mỗi lane 2 hoặc 3 GameOver/lobby/writeEnds; tất cả client/native exit 0, 0 worker errors, cleanup ports PASS. Log `scratch/evidence/hegemony-runtime-parity-20261127/tl-seeded-*.log`. Binary/manifest như trên; TS SHA-256 `336693ac8791296361f678b9a3e1cf932b90196b1aab2650086064d069388d9e`, Lua `99fd0af5d8bf87f72a58d3ce0df41dff5043192459956cb7f762321ecda9e5b`. TL-01–04 bounded trace/seed đạt; TL-05 source probe đã đạt, chưa native riêng. Không thay Core trong mốc này.

### Ma trận Thành Lược

| Case | Thiết lập và thao tác | Điều kiện đạt |
| --- | --- | --- |
| TL-01 · View-as và kết toán trực tiếp | Dùng một bài cơ bản thành Hỏa Công qua `PlayCard`. Mục tiêu lộ một lá, người dùng bỏ lá khác đúng chất. | View-as mang đúng skill và một subcard. Chi phí vào chồng bỏ, mục tiêu mất 1 HP do sát thương hỏa, đúng lá đã lộ vào chồng bỏ một lần. Hai client đồng thuận về thông tin công khai. |
| TL-02 · Hủy chi phí | Chọn lá lộ rồi hủy ở prompt bỏ bài của người dùng. | Giữ lá định dùng làm chi phí, lá lộ ở nguyên vùng, 0 sát thương và không có lượt bỏ lá do Thành Lược. |
| TL-03 · Sát thương bị chặn | Trả chi phí hợp lệ; trigger QA chặn tại `DamageInflicted` theo cờ ngăn sát thương của Core. | Chi phí đã bỏ, trigger chặn chạy đúng một lần, HP không đổi, không có `fk.Damage` thành công hoặc lượt bỏ lá do Thành Lược. |
| TL-04 · Sát thương lan truyền | Bố trí người dùng, mục tiêu trực tiếp và một ghế thứ ba đều hợp lệ theo luật; nối xích hai mục tiêu. Ghế lan có bài đối chứng riêng. | Hai mục tiêu chịu đúng sát thương hỏa, event ở ghế thứ ba có `chain = true`, chỉ mục tiêu trực tiếp bỏ lá đã lộ. Bài đối chứng còn nguyên và giữ bí mật. |
| TL-05 · Lá lộ rời vùng hoặc bị cấm bỏ | Tạo hai biến thể có hiệu ứng hợp lệ chuyển lá ra khỏi tay/trang bị hoặc áp dụng `prohibitDiscard` trước lần Thành Lược kiểm tra. | Sát thương hợp lệ vẫn kết toán. Thành Lược bỏ 0 lá và không chọn lá thay thế. Chạy native khi hook Core/move thay đổi; probe source cho cả hai biến thể phải tiếp tục PASS. |

## 3. P1 · Ký Ly bằng hiệu ứng thật của Quốc Chiến

Nguồn luật là `TargetConfirmed` của `ld__jilix` trong `lord_ex`. Kỹ năng buộc chọn một trong hai nhánh khi chủ kỹ năng là mục tiêu duy nhất của bài cơ bản đỏ hoặc cẩm nang thường đỏ. Dùng Sát đỏ với nạn nhân sống qua cả hai lượt, kiểm cả mốc kết toán và delta HP để phân biệt chính xác lượt kết toán với kết quả chặn sát thương. Các case lịch sử CP15 theo hành vi cũ được giữ làm bằng chứng theo revision cũ. [Ký Ly hiện hành](../../runtime/packages/hegemony/pkg/lord_ex/skills/jilix.lua) · [Audit luật](QUOC_CHIEN_RULE_AUDIT.md)

| Case | Thiết lập và thao tác | Điều kiện đạt |
| --- | --- | --- |
| KL-01/KL-02 · Thêm lần kết toán | Chạy riêng Nghiêm Bạch Hổ ở ô chủ và ô phó; chọn `ld__jilix_effect`. | Một prompt với hai tùy chọn. Lá bài kết toán hai lần, kỹ năng và ô sở hữu còn nguyên. Với Sát đối chứng không Né và không có hiệu ứng đổi sát thương, HP giảm tổng 2. |
| KL-03/KL-04 · Loại bỏ tướng | Chạy riêng từng ô với `ld__jilix_remove`. | Lá bài kết toán đúng một lần, kỹ năng mất, đúng ô sở hữu bị thay bằng lính hợp luật, ô còn lại giữ trạng thái. Kiểm `removeGeneral` đi qua event thật và cập nhật public/owner phù hợp. |
| KL-05 · Điều kiện và biến thể | Sát đen, cẩm nang kéo dài đỏ, bài đỏ đang có nhiều mục tiêu; thêm một đối chứng cẩm nang thường đỏ một mục tiêu. Kiểm cả ô ẩn với prelight/reveal qua đường thật. | Ba đối chứng âm tạo 0 prompt `ld__jilix`; cẩm nang thường đỏ hợp lệ tạo một prompt. Kiểm bí mật ô còn ẩn và phân biệt `nos_heg__jilix`. |

**Evidence 11:16:** KL-05 `hidden-main-effect` native 2 socket Card Wire v1 PASS giới hạn, 1 prelight owner-only, 1 invoke, 1 choice, reveal trước SkillEffect, 2 kết toán/2 sát thương, 2 GameOver/lobby, cleanup PASS. Log `scratch/evidence/hegemony-runtime-parity-20261127/kl05-hidden-main-effect-invoke.log`. Bài vật lý được fixture đưa trực tiếp qua `room:useCard`; các nhánh/đối chứng còn lại và packet privacy tướng ẩn chưa đóng.

**Evidence 11:19:** Sáu lane PlayCard độc lập với DB mới và seed hành động `20261127:5` sau chia bài PASS: main/deputy × effect/remove, black, unlit. Log `kl05-hidden-*-seeded-playcard.log`. Trick native xác minh hai lượt lấy bài, nhưng client FAIL tại đếm AskForCardChosen; không dùng lượt này đóng gate do fallback khi hết thời gian. Rerun responder theo command đang thực hiện. Delayed/multi và privacy packet tướng ẩn còn mở.

**Evidence 11:21:** Rerun trick, delayed, multi đều PASS (`kl05-*-choice-rerun.log`), tổng 9/9 lane. Trick trả hai token chọn bài hợp lệ và hai lượt obtain; delayed ở vùng phán định; multi hai mục tiêu, ba socket. Không có invoke/choice ở hai đối chứng âm. Tất cả client/native exit 0, GameOver/lobby và cleanup PASS. Gate KL-05 còn cần packet privacy tướng ẩn và phân biệt nos.

**Evidence 11:23:** Ba lane main-effect, deputy-remove, multi PASS với kiểm packet theo phase `tqs_qa_hidden_phase`: `SetPlayerMark` tướng thật, `AddSkill` fake và prelight chỉ tới owner; `PropertyUpdate` reveal đúng ô, ô kia vẫn ẩn; multi không reveal. Trace `CardEffecting`/`Damaged` của chủ kỹ năng 2/2, 1/1, 1/1. Client/native exit 0, worker errors 0, 2/2/3 GameOver/lobby/writeEnds, cleanup PASS. Session 51052, log `kl05-hidden-*-identity-privacy.log`. Regression playcard/chain session 88452 PASS (`kl05-{playcard,chain}-choice-rerun.log`). Chưa kiểm reconnect/observer hoặc mọi kênh tướng ẩn.

**Evidence 11:24:** Đối chứng `hidden-decline` native PASS, 1 invoke bị hủy, 0 choice/SkillEffect, 1 kết toán/1 sát thương, không reveal, privacy packet PASS và cleanup PASS. Tổng 10/10 lane hiện hành. Probe [nos](../../deploy/freekill-native/qa/jilix-nos-source-probe.lua) 10/10 trên mỗi nguồn local/pin/staging production, xác nhận tag DeputyPlace, tự thêm kết toán và ngăn lần sát thương thứ hai theo HistoryPhase rồi loại phó; không có choice ld. Log `kl05-nos-source-probe.log`; native nos chưa chạy.

Dùng case độc lập theo ô và nhánh; fixture chọn tướng cần đồng bộ tướng thật, mark `__heg_general`/`__heg_deputy`, fake skill và trạng thái reveal. Khi kiểm loại bỏ, kỳ vọng `blank_shibing` hoặc `blank_nvshibing` theo luật trong `remove_general.lua`. Chrome runner hỗ trợ `hidden-jilix` và `hidden-jilix-deputy` với native QA và `--manual`. Chọn nhánh bằng `TQS_LIVE_HIDDEN_JILIX_BRANCH=effect` hoặc `remove` (mặc định). Runner kiểm cả hai client nhận xác nhận branch và slot từ native QA. [Runner Chrome](../../game/web/scripts/multiplayer-e2e/run.ts) · [Fixture QA](../../deploy/freekill-native/qa/tqs_qa/init.lua) · [Luật loại tướng](../../runtime/packages/hegemony/utilevent/events/remove_general.lua)

## 4. P1/P2 · Rà 27 file Core và 13 module Card Wire

Đối chiếu `*.lua` dưới `packages/freekill-core/` của runtime local với overlay 15/11 bằng đường dẫn tương đối và SHA-256 nội dung chuẩn hóa LF. Inventory đã kiểm lại có 13 file chỉ ở overlay, 0 file chỉ ở local và 27 file chung khác nội dung. Với điểm chạm nghi ngờ, lấy diff ba phía local → overlay → production đang dùng trong ZIP lưu. Ghi symbol, caller trong `new_heg_mode`, parity hoặc sai khác quan sát được, quyết định giữ/chuyển có chọn lọc/hoãn và bài test chứng minh theo từng file.

### Bảy file cần mở trước

| File dưới Core | Điểm chạm thấy khi đọc diff | Bài kiểm để quyết định |
| --- | --- | --- |
| `ltk/server/events/usecard.lua` | Overlay bỏ lần `filterCard` đối với lá phản hồi vật lý trong `RespondCard`. Cùng file điều phối `CardEffect` và tiêu thụ `additionalEffect`. | So sánh số lượt kết toán KL-01–04, phản hồi mục tiêu, parent effect TL-01/TL-04; chỉ đề xuất chỉnh logic khi trace xác nhận. |
| `ltk/server/events/movecard.lua` | Overlay giữ cả `visiblePlayers` dạng ID số đã được chuyển đổi. | Di chuyển bài tay → công khai → bỏ; kiểm đúng audience cho danh sách ID và object, cả outsider và reconnect. |
| `ltk/core/player.lua` | Overlay xử lý alias Card Wire không có Card object theo hướng giữ bí mật. | Alias tay/ẩn trên client và bài công khai, đối chiếu view của hai ghế và reconnect. |
| `ltk/core/skill_type/active.lua` | Khác xử lý interaction, điều kiện khả thi và tự xác nhận. | Chọn/hủy đúng lá ở Hỏa Công, đúng mục tiêu, bật/tắt Xác nhận theo lựa chọn hợp lệ. |
| `ltk/core/skill_type/usable_skill.lua` | Overlay xử lý giá trị giới hạn theo scope khi tra `max_use_time`. | Thử kỹ năng có giới hạn và kiểm reset tại scope thích hợp; ghi rõ caller Hegemony nếu có. |
| `ltk/server/room.lua` | Khác projection mark, tướng ẩn, serialize, prompt lựa chọn và đường `filterUseCard`. | TL-01–04, KL-01–05, choice/normalize reply và snapshot reconnect giữa request. |
| `ltk/server/serverplayer.lua` | Khác đường thông báo fake/prelight, viewer và tham số đổi controller. | So sánh chủ sở hữu/đối thủ/observer với tướng chưa lộ, loại đúng ô, và reconnect khác socket. |

### Hai mươi file lệch còn lại

| Nhóm | File dưới Core | Điều kiện nghiệm thu |
| --- | --- | --- |
| Dispatcher, request và role | `ltk/server/events/misc.lua`, `lua/server/request.lua`, `lua/server/roombase.lua`, `lua/server/rpc/dispatchers.lua`, `lua/server/serverplayer_base.lua`, `ltk/core/room/abstract_room.lua` | Kiểm vòng request/reply, owner, role change, reveal, người xem và hủy scope. Với mỗi nhánh chưa phát packet trong lượt thử, ghi rõ coverage còn mở. |
| Client và registry | `ltk/client/client.lua`, `lua/client/client.lua`, `lua/client/client_util.lua`, `lua/client/clientbase.lua`, `lua/fk_ex.lua`, `lua/freekill.lua`, `standard/aux_skills_dir/ex__choose_skill.lua` | Kiểm nạp registry, callback parser, projection và UI lựa chọn thực. Ưu tiên đường dùng bởi Quốc Chiến. |
| Tửu và các loại Sát | `maneuvering/pkg/skills/analeptic.lua`, `maneuvering/pkg/skills/fire__slash.lua`, `maneuvering/pkg/skills/thunder__slash.lua`, `standard_cards/pkg/skills/slash.lua` | Dựng chủ thể thật hoặc SmartAI request loop với input tương đương, xác minh Tửu và Sát thường/hỏa/lôi, `additionalDamage` và sát thương thực tế. Giữ behavior đã có bằng chứng khi hợp nhất delta. |
| Skin và ngôn ngữ | `ltk/core/skin_package.lua`, `lua/client/i18n/en_US.lua`, `lua/client/i18n/zh_CN.lua` | Ưu tiên nếu ảnh hưởng boot/registry hoặc prompt có thể thao tác được. Ghi lý do hoãn khi chỉ là skin/QML hay chuỗi ngoài luồng Quốc Chiến. |

### Mười ba module chỉ có ở overlay

| Nhóm | File dưới Core | Đối chứng |
| --- | --- | --- |
| Chín module client trong `ltk/client/` | `card_wire_area.lua`, `card_wire_deck.lua`, `card_wire_metadata.lua`, `card_wire_moves.lua`, `card_wire_negotiation.lua`, `card_wire_public.lua`, `card_wire_refs.lua`, `card_wire_requests.lua`, `card_wire_snapshots.lua` | Negotiation trước draw, deck đếm số lá, chuyển vùng và công khai đúng audience, alias và request hợp lệ, snapshot sau reconnect. |
| Bốn module server trong `lua/server/` | `card_handle_protocol.lua`, `card_wire_projection.lua`, `card_wire_request.lua`, `card_wire_secure_mint.lua` | Đi đúng module của runtime QA, cấp/thu hồi handle theo kết nối và request, kiểm quyền xem, giữ các đường công khai Hỏa Công và riêng tư của bài/tướng. |

Mỗi delta cần kết luận có dẫn chứng. Giữ đường legacy cho local khi bài test chứng minh hành vi phù hợp với mục đích fixture. Với lỗi tái hiện từ Quốc Chiến, chuyển phần vá tối thiểu kèm test và kiểm lại hash/manifest của thành phần bị ảnh hưởng. Nghiệm thu Card Wire v1 trên runtime QA có đầy đủ module. Chạy lại choice và draw/reconnect nếu thay đổi projector, handle hoặc `MoveCards`. [Contract Card Wire](../../deploy/freekill-native/qa/upstream-first-source.test.mjs) · [Hướng dẫn nghiệm thu live](LIVE_TESTING.md)

### Kết quả rà delta 11:28 — local, overlay 15/11 và ZIP production 27/11

Inventory SHA-256 chuẩn hóa LF kiểm lại trực tiếp: local 309, overlay 322, production 323 Lua. Local → overlay: 27 sửa, 13 thêm, 0 xóa. Overlay → production: 21 sửa, 1 thêm. Local → production: 28 sửa, 14 thêm, 0 xóa. Staging native 323/323 khớp production theo LF. Quyết định trong đợt này: giữ local legacy có chủ đích và dùng staging production Card Wire cho native/web QA; không nâng pin hay merge hàng loạt. Các dòng dưới đây ghi kết luận đọc source/diff và coverage có thật, không đồng nhất source audit với runtime PASS.

| File Core | Symbol/đường gọi và quyết định | Bằng chứng và coverage còn mở |
| --- | --- | --- |
| `ltk/client/client.lua` | Khởi tạo refs, `moveCards`, `prepareDrawPile`, deck/pile/area dispatch; giữ v1 ở ZIP, legacy ở local. | Require 9 module xác nhận; native TS socket chưa chạy Lua client. Chrome/reconnect cần kiểm. |
| `ltk/core/player.lua` | `cardVisible` xử lý opaque alias không có Card; giữ projection v1. | Native TL-04 grant/ShowCard/MoveCards đúng audience; Lua client alias và observer chưa kiểm. |
| `ltk/core/room/abstract_room.lua` | `filterCard` nil owner xóa filter; giữ source production. | TL PlayCard đạt; reset filter riêng khi đổi owner chưa kiểm. |
| `ltk/core/skill_type/active.lua` | OptionBox, autoTarget, guard auto-confirm/feasible; giữ bản v1. | Native PlayCard và choice đạt; UI target/confirm phải kiểm Chrome. |
| `ltk/core/skill_type/usable_skill.lua` | `getMaxUseTime` nhận function-valued scope; không thấy literal `max_use_time`/`maxUseTime` trong Hegemony local qua rg. Giữ bản production, hoãn port legacy. | Chưa có case reset scope động; không suy ra từ TL/KL. |
| `ltk/core/skin_package.lua` | Delta annotation skin; không sửa luật Quốc Chiến. | Source inventory; hoãn skin/QML. |
| `ltk/server/events/misc.lua` | `changeRole` kết thúc khi các ghế sống cùng phe; Hegemony `part_ways.lua` gọi chuyển wild. Giữ production. | GameOver fixture không kiểm winner-law; ván tự nhiên còn mở. |
| `ltk/server/events/movecard.lua` | Bảo toàn `visiblePlayers` kiểu ID số đã convert, giữ projection production. | TL-04 đúng 3 audience và lá bỏ; dạng số/object riêng và reconnect chưa đủ. |
| `ltk/server/events/usecard.lua` | `RespondCard` bỏ filter vật lý trùng, `CardEffect`/additionalEffect dùng đường gốc. Giữ production. | Trace TL parent/1 resolution và KL 1/2 resolution PASS; response vật lý có filter chưa kiểm. |
| `ltk/server/room.lua` | SetCardMark private, gender noBroadcast, serialize, choice visibility, `filterUseCard` theo owner thật. Giữ bản v1. | TL/KL request và mark/show thực đạt; serialize reconnect/observer, filter owner đổi còn mở. |
| `ltk/server/serverplayer.lua` | pairs status skill, fake/prelight physical-only, revealed slot tracker. Giữ bản v1. | KL owner-only prelight/fake/mark, reveal đúng ô PASS; reconnect/controller và observer mở. |
| `lua/client/client.lua` | callback negotiation/snapshot/public/metadata/request và replay invite guard. Giữ v1 dispatch. | Đường require xác nhận; Chrome/Wasmoon và snapshot còn mở. |
| `lua/client/client_util.lua` | `ReplyToServer` encodeReply v1, gameData. Giữ v1. | Native TS reply đúng token không chứng minh encoder Lua; Chrome còn mở. |
| `lua/client/clientbase.lua` | `ArrangeSeats` advertise, snapshot state, endMatch/gameData. Giữ v1. | Native v1 negotiate/GameOver/lobby PASS; client Lua và snapshot còn mở. |
| `lua/client/i18n/en_US.lua` | Delta comment None; hoãn ngoài luồng. | Đọc diff; không thay Việt hóa. |
| `lua/client/i18n/zh_CN.lua` | Chuỗi invite/title; giữ production, hoãn ngoài luồng Quốc Chiến. | Đọc diff; prompt Việt hóa đã có test riêng. |
| `lua/fk_ex.lua` | Annotation dynamic num; giữ production, hoãn chuyển legacy. | Đọc diff; chưa chứng minh dynamic count riêng. |
| `lua/freekill.lua` | Allow đọc binary `/dev/urandom` cho secure mint; giữ bản production. | Native v1 request/alias đã được cấp; không chứng nhận entropy từ distinct aliases. |
| `lua/server/request.lua` | Projection, atomic allowlist, resolveChoice và cleanup theo request; giữ v1. | PlayCard, chọn/lộ/bỏ và hủy, KL trick token/invoke/choice PASS; stale/reconnect riêng mở. |
| `lua/server/roombase.lua` | Negotiation, audience, batch, projection, snapshot/private/role; giữ v1. | v1 negotiate, TL/KL privacy bounded PASS; snapshot/observer mở. |
| `lua/server/rpc/dispatchers.lua` | Kiểm kiểu params[3], bỏ race room-not-found; giữ production. | Native boot/dispatch/quit sạch; race riêng chưa kiểm. |
| `lua/server/serverplayer_base.lua` | Projection mỗi socket, batch, returning socket negotiation/snapshot, gameData; giữ v1. | TL/KL audience và lobby PASS; reconnect khác socket chưa kiểm. |
| `standard/aux_skills_dir/ex__choose_skill.lua` | Match alias được offer trong active request; giữ v1. | TL/KL lựa chọn hợp lệ PASS; alias hết hạn cần kiểm. |
| `maneuvering/pkg/skills/analeptic.lua` | Local và production đã khớp LF; không chuyển bản overlay cũ. | Byte parity; chưa có test AI Tửu mới riêng. |
| `maneuvering/pkg/skills/fire__slash.lua` | Local và production đã khớp LF; giữ. | Byte parity; test sát hỏa riêng còn mở. |
| `maneuvering/pkg/skills/thunder__slash.lua` | Local và production đã khớp LF; giữ. | Byte parity; test sát lôi riêng còn mở. |
| `standard_cards/pkg/skills/slash.lua` | Local và production đã khớp LF; giữ. | KL Sát đỏ/đen PASS bounded, không chứng minh mọi additionalDamage/response. |
| `ltk/client/clientplayer.lua` | Delta mới production: bỏ filter đối với opaque alias; giữ v1. | Source audit; Lua client Chrome còn mở. |
| `ltk/core/engine.lua` | Delta mới production: lookup clone mặt bài theo request; giữ v1. | Source audit; scoped face release/stale còn mở. |
| `lua/server/rpc/cbor.lua` | Delta mới production: zero length, assert truncated stream, EOF decode_file; giữ production. | Native boot và request PASS, malformed stream chưa thử riêng. |
| `lua/server/rpc/stdio.lua` | Delta mới production: finished trả nil trừ đọc zero; giữ production. | Worker shutdown PASS, đọc biên riêng còn mở. |
| `lua/server/scheduler.lua` | Delta mới production: log dispatch capability; giữ production. | Native v1 boot/negotiation PASS, không đổi scheduler. |

| Module bổ sung production | Nơi nạp và phạm vi bằng chứng |
| --- | --- |
| `ltk/client/card_wire_area.lua` | `ltk/client/client.lua` require, area dispatch; kiểm Chrome còn mở. |
| `ltk/client/card_wire_deck.lua` | `ltk/client/client.lua` require, Prepare/Shuffle/SyncDrawPile; native không chứng minh Lua decoder. |
| `ltk/client/card_wire_metadata.lua` | `ltk/client/client.lua` require, `lua/client/client.lua` metadata callback; ShowCard/MoveCards native đạt, metadata Lua còn mở. |
| `ltk/client/card_wire_moves.lua` | `ltk/client/client.lua` require và receive/receivePile; native MoveCards đạt, Lua apply/retire còn mở. |
| `ltk/client/card_wire_negotiation.lua` | `ltk/client/client.lua` require, `lua/client/clientbase.lua` advertise/endMatch, `lua/client/client.lua` receive; v1 native đạt, Lua client mở. |
| `ltk/client/card_wire_public.lua` | `ltk/client/client.lua` require, `lua/client/client.lua` public callback; ShowCard native đạt, Lua client mở. |
| `ltk/client/card_wire_refs.lua` | `ltk/client/client.lua` require/new; TL outsider aliases đúng, Lua refs/rekey mở. |
| `ltk/client/card_wire_requests.lua` | `ltk/client/client.lua` require, `lua/client/client.lua` receive, `lua/client/client_util.lua` encodeReply; native token choice đạt, Lua encoder mở. |
| `ltk/client/card_wire_snapshots.lua` | `ltk/client/client.lua` require, `lua/client/client.lua` receive/dispatch; reconnect mới cần chứng minh. |
| `lua/server/card_handle_protocol.lua` | `lua/server/roombase.lua` require/new, reference/standing/choice/batch; TL privacy và KL reply đạt bounded, disconnect/rekey mở. |
| `lua/server/card_wire_projection.lua` | `lua/server/roombase.lua` require; MoveCards/ShowCard/mark audience TL/KL đạt bounded; observer/shuffle/snapshot còn mở. |
| `lua/server/card_wire_request.lua` | `lua/server/roombase.lua` require, request scope; TL PlayCard và KL invoke/choice đạt; stale/reconnect mở. |
| `lua/server/card_wire_secure_mint.lua` | `lua/server/roombase.lua`, `lua/server/request.lua` require; v1 mint sử dụng thực, không suy ra bảo chứng entropy. |
| `ltk/core/card_wire_request_visibility.lua` | Module thứ 14 mới production, được cả `ltk/client/card_wire_requests.lua` và `lua/server/card_wire_request.lua` require; request selection native đạt, Lua request face lifecycle mở. |

**Kết luận audit:** 27 delta lịch sử + 5 delta mới có quyết định phạm vi, 4 delta lịch sử đã khớp production, 14 module có wiring xác nhận từ source. Không có bằng chứng mới buộc vá Core trong TL/KL native vừa chạy. Gate rà source/inventory hoàn tất; gate hành vi theo nhánh còn mở (response filter, role/GameOver tự nhiên, client Lua, snapshot/reconnect, observer và các case được ghi trên). Không chốt toàn bộ Core/Card Wire là runtime PASS.

## 5. P2 · Chrome, reconnect và thiết bị thật

**Trạng thái ngày 27/11/2026:** đóng mục QA live theo quyết định của người dùng và chuyển kiểm tra trực tiếp sang người chơi thử nghiệm. Chỉ chạy kiểm tra mã và kiểm tra tự động. Các ca live chưa chạy giữ trạng thái chưa xác minh. Các bước và tiêu chí bên dưới dùng để đối chiếu khi có phản hồi.

Fixture Chrome/Wasmoon `npm --prefix game/web run test:e2e:lua -- --jilix` đã kiểm hai lựa chọn tiếng Việt, đóng socket khi prompt đang chờ, phát lại cùng request ID trên socket mới và bỏ packet đến muộn từ socket cũ. Lượt native `hidden-main-effect` chạy riêng trên manifest `2c4e29161bc0b2d37fdc3c0e67486745` cũng PASS. Gate tích hợp bên dưới vẫn mở. Runner multiplayer và QA package đã chuẩn bị hai nhánh. Với riêng Ký Ly, `--manual --reconnect` đóng socket tại prompt, yêu cầu packet `Reconnect` mới và chỉ trả lời choice đến sau snapshot. Chưa chạy lượt Chrome live với package QA và runner mới.

Runner `deploy/freekill-native/qa/skill-parity/run.py` nhận cờ `--gateway` để chạy cùng các lane qua WebSocket loopback và đối chiếu manifest gateway với native. Cờ `--browser-preflight` kiểm Chrome tải ZIP từ chính gateway, xác minh checksum bằng loader của web, khởi động Wasmoon và vào sảnh qua socket thật. Phiên Chrome preflight dùng tài khoản chỉ tồn tại trong DB QA tạm. Các lane gameplay có bộ xác nhận packet riêng.

Kết quả staging: 4/4 Ký Ly và 5/5 Hỏa Công/Thành Lược qua gateway, gồm kiểm MoveCards/ShowCard ba audience ở TL-04. Chrome preflight PASS trên manifest `2c4e29161bc0b2d37fdc3c0e67486745`, bundle staging `9ea23e67fda74a99`, 5.339 tệp và 0 lỗi Lua. Gate Chrome gameplay vẫn chờ thao tác React trong ván với hai client và reconnect tại prompt.

1. Sau native PASS, đưa cùng Lua/runtime manifest lên gateway QA cô lập. Chạy hai client Chrome với bundle nhận diện được và tài khoản/ticket QA qua cơ chế được repo hỗ trợ. Chọn phòng Quốc Chiến, vào phòng thứ hai, chọn cặp chủ–phó hợp lệ, dùng skill và trả lời prompt qua UI thật. Chạy desktop và viewport điện thoại 390×844. Đo prompt tiếng Việt, nút Xác nhận/Hủy, hiệu ứng công khai và đúng slot sau choice. Chạy `hidden-jilix` hai ô với `TQS_LIVE_SCENARIO` và `npm run test:e2e:multiplayer -- --manual` sau khi đã cấu hình identity/runtime theo runbook. Thành Lược cần bổ sung case UI đi qua `PlayCard`, chọn bài cơ bản và xác nhận mục tiêu. [Quy trình live](LIVE_TESTING.md) · [Việt hóa prompt](../../game/web/src/engine/vietnameseHegemonyUpdates.ts)
2. Rút kết nối một client khi đang chờ prompt Hỏa Công hoặc Ký Ly, khôi phục cùng ghế rồi trả lời. Kiểm request/snapshot hiện tại, không kết toán thêm do reconnect, không dùng handle cũ thuộc kết nối trước, đúng lá đã công khai và dữ liệu riêng chỉ hiển thị cho chủ thể. Với browser QA có observer, kiểm spectator độc lập và ghi theo kênh thực sự phát packet. Kết thúc bằng `GameOver`, về sảnh và clean disconnect khi scenario đi qua các bước đó.
3. Giữ trạng thái riêng cho ván hoàn chỉnh có GameOver tự nhiên, phiên OAuth production và điện thoại thật. Khi được yêu cầu kiểm OAuth production, ưu tiên tab Chrome QA đang đăng nhập. Đóng gate CLI chỉ khi chạy runner public trên phiên được phép và có evidence thật. Với điện thoại thật, ghi thiết bị/OS, thao tác cảm ứng, xoay màn và reconnect. Chrome viewport cung cấp chứng cứ mô phỏng giao diện điện thoại. [Quy trình live](LIVE_TESTING.md)

## 6. Cổng hoàn tất và ghi bằng chứng

| Gate | Tiêu chí đóng |
| --- | --- |
| Baseline source | `check:upstream-baseline`, probe Thành Lược/Ký Ly trên ba nguồn, `test:qa-server-contract` và `git diff --check` đều PASS. Với thay đổi web chạy thêm `test:hegemony-translation` và typecheck. |
| Native gameplay | TL-01–04, KL-01–05 và các biến thể trực tiếp bị tác động đạt assertion trên native/Card Wire v1. TL-05 có probe source và được chạy native nếu sửa đường move hoặc điều kiện bỏ. Từng case có mốc request/reply, kết toán, hai client `GameOver`, số lỗi worker/client bằng 0 và cleanup. |
| Core | 27 delta lịch sử + 5 mới có quyết định (4 đã khớp production), 14 module có xác nhận đường nạp hoặc phạm vi legacy. Lỗi có thể ảnh hưởng luật hoặc bí mật thông tin phải được sửa và chạy regression trước khi chốt đợt nghiệm thu. |
| Chrome QA | Prompt/lựa chọn Thành Lược và hai nhánh Ký Ly qua UI, slot đúng ở cả hai vị trí, reconnect và kiểm thông tin theo người xem đạt trên cùng runtime với lượt native đã xác minh. |
| Nghiệm thu TQSVN rộng hơn | Ván có GameOver tự nhiên, OAuth production và điện thoại thật có evidence riêng khi thực hiện. |

Mỗi lượt ghi ngày, case, source revision, hash binary/runtime/QA/web tương ứng, seed, cấu hình ghế ở dạng phân loại, mốc request/response, số lượt kết toán, delta HP, boolean ownership/move/privacy đúng và kết quả cleanup. Chỉ lưu metadata đã lọc. Giữ credentials, token, payload thô, card/target ID, bài tay/tướng riêng và exception thô ngoài artifact. Phân biệt trạng thái **PASS**, **FAIL**, **chưa chạy** và **bị chặn**, kèm mốc cuối quan sát được. Cập nhật [CODEX_STATE](../CODEX_STATE.md) và [CODEX_PLAN](../CODEX_PLAN.md) sau mỗi mốc, rồi chạy `npm run codex:checkpoint`.

**Bước tiếp theo để triển khai.** Runner tái lập, Hỏa Công vật lý/Thành Lược qua `PlayCard` và gameplay sát thương lan TL-04 đã đạt giới hạn nêu trên. Đối chiếu MoveCards/ShowCard public/owner/outsider TL-04 đã PASS có giới hạn. KL-05 ld 10/10 native bounded, nos source probe và trace/seed hành động TL-01–04 PASS. Đã rà delta Core/Card Wire. Kiểm tra Chrome và reconnect trực tiếp được chuyển sang người chơi thử nghiệm.
