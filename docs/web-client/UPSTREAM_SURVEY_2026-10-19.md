# Khảo sát upstream và tính khả thi U0–U8 — 19/10/2026

**Kết luận sau khi chốt phạm vi với người dùng:** nâng **Hegemony/Quốc Chiến `new_heg_mode` và phụ thuộc cần thiết**, giữ pin các repo còn lại. Không cần nâng nguyên bộ 14 HEAD mới. Blocker Mobile/Mưu Công bên dưới thuộc tổ hợp nâng toàn hệ sinh thái, không phải blocker bắt buộc của bản nâng Hegemony riêng. U0–U2 có thể bắt đầu; U5 vẫn phải nghiệm thu danh mục tướng/bài thay đổi. Chưa đủ điều kiện candidate hoặc production.

## Phạm vi TQSVN đã đối chiếu lại

- API session và policy dùng `new_heg_mode`; catalog cấu hình có 14 nhóm tướng + 4 nhóm bài của Hegemony. `mobile_heg`, `online_heg`, `tenyear_heg`, `overseas_heg` đều là thư mục trong repo Hegemony, không đồng nghĩa triển khai toàn bộ mode/nội dung của các repo Mobile/OL/Tenyear/Overseas.
- Native installer và browser loader hiện vẫn nạp 14 repo runtime. Ngoài engine/core và utility, các repo extension cung cấp implementation skill/card/helper mà tướng Hegemony gọi theo tên. Ví dụ `m_heg__zhoufang` khai báo `duanfa`, implementation ở `tenyear/pkg/tenyear_xinghuo/skills/duanfa.lua`; `os_heg__yangxiu` dùng `danlao` từ `SP/pkg/sp/skills/danlao.lua`.
- **Đã chạy lại trong lần chốt scope:** `npm --prefix game/web run audit:skills -- --json` PASS; baseline 3 repo core/utility/Hegemony thiếu 203 direct skill IDs (205 occurrences) trong inventory Hegemony được audit, chưa giới hạn mọi ID đó vào pool active. Bộ dependency đầy đủ cho 0 visible unresolved và 0 active general skill-contract failures. Không suy ra cả 11 repo phụ là tập tối thiểu chỉ từ kết quả này.
- Probe mới `hegemony-scope-probe.ts`: baseline START PASS, 301 active/visible tướng, 0 reference active thiếu; chỉ thay Hegemony bằng `d069cd1`, giữ toàn bộ dependency pin cũ: START PASS, 233 active/visible tướng, 0 reference active thiếu, 0 warning/error log. Chưa chứng minh đầy đủ effect/native/gameplay hoặc mọi dependency gián tiếp.
- **Nguyên tắc quan tâm thay đổi:** ưu tiên diff Hegemony; trong repo phụ chỉ audit skill/helper/card/API dùng trực tiếp hoặc gián tiếp, privacy/protocol/lifecycle chung, và code nạp registry có thể gây lỗi toàn runtime. Nội dung của mode/tướng không liên quan có thể nằm ngoài backlog. Không tự nâng dependency hoặc xóa repo hiện đang nạp.
- **Điều chỉnh khuyến nghị trước:** migration Mobile/Mưu Công chỉ mở khi thực sự nâng Mobile; core mới là tùy nhu cầu tương thích. Thống kê 171 commit không còn được dùng làm phạm vi triển khai bắt buộc. Các mục khảo sát toàn HEAD bên dưới giữ làm bằng chứng tham khảo.

Đối chiếu remote bằng `git ls-remote` ngày 19/10/2026, lượt ghi nhận đầu lúc **15:40 giờ Việt Nam** (08:40 UTC), sau đó fetch object và kiểm ancestry/diff trong thư mục khảo sát riêng. Các SHA dưới đây là snapshot mục tiêu khảo sát, **chưa phải pin được chấp nhận để phát hành**.

## 1. Remote và khoảng cách mới

Tất cả 15 repository đã đọc được remote, lấy được commit đích, và pin hiện tại đều là ancestor của đích. Hai lần timeout ban đầu với `standard_ex`/`yj` đã được retry thành công; không còn remote chưa xác thực.

| Repository | Pin TQS | HEAD khảo sát (đủ SHA) | Commit lệch | So với báo cáo 17/10 |
| --- | --- | --- | ---: | --- |
| freekill-core | ade837d | `5337ea1bbf4beabeee950e88329da3e8bd91eb09` | 50 | +3 |
| hegemony | d616978 | `d069cd1f5c6df8d93af0ea101b82a5bed2781f01` | 7 | +2 |
| tenyear | 91a769c | `dd84862550b150d46ade2fc2068a29b20ff51635` | 37 | Không đổi |
| OL | ceee01b | `b33d6536788050a8170904ddbc53616246508685` | 35 | +1 |
| mobile | dcd523c | `6aac75a7201779ab62a20e73df8667142bc3012e` | 17 | Không đổi |
| utility | f86d3d0 | `c190c6fa6062856f352e48d2ae0917e96dce33fb` | 8 | Không đổi |
| gamemode | cf16826 | `ba1053ef227e2c11eb997e6464995609ae00189f` | 4 | Không đổi |
| SP | ab42a3f | `8101643fe96125aca29bbf0615d402982ef00cab` | 4 | Không đổi |
| overseas | 6780626 | `fddc212086322f521b8dd745964c37fc010274bb` | 5 | +1 |
| yj | 10edd0f | `4954989c9b987320cf2a55c884b1202ffa8792f2` | 2 | Không đổi |
| shzl | a6743be | `20e0628108ab1a4f17f8f8b7694b5e36e8a01af5` | 1 | Không đổi |
| freekill-asio | b8a2ad4 | `f766e7403b42f6259757b8b27293f843c91863c5` | 1 | Không đổi |
| standard_ex | b041d9d | `b041d9d4151d436bb6c357f7b772fa2f1a040df0` | 0 | Không đổi |
| mougong | 2ce058e | `2ce058ec5aaceda4ebe3517278612a3d41e26045` | 0 | Không đổi SHA, nhưng có xung đột với Mobile mới |
| jsrg | 36201e7 | `36201e75a6afc2a6f35a96bb07f4cd9a8a983193` | 0 | Không đổi |

Tổng **171 commit-distance**, tăng 7 so với 164. Đây không phải 171 thay đổi luật độc lập. `hegemony` hiện có 194 file thay đổi, 4.841 dòng thêm/1.386 dòng xóa giữa pin và target; core có 86 file, 4.030 dòng thêm/391 dòng xóa. Các thống kê mới được tính lại từ Git, không tái sử dụng thống kê cũ.

Thay đổi sau mốc cũ cần thêm vào acceptance:

- Hegemony `c12ee33`: Quốc Chiến 27珍藏, thêm/sửa Gia Cát Khác, Tô Phi, Hứa Du, Bành Dạng, Tôn Lâm và bốn trang bị chuyên dụng. `d069cd1`: Quốc Chiến Mobile Từ Thứ/Bành Dạng. Diff mới còn chạm Thiên Hương, các skill `lord_ex`, bài và chuyển tướng.
- Core `1fd47a16`: xét GameOver sau thay đổi identity khi chỉ còn một phe; đây là delta server/rule cần test, ngoài hai commit còn lại về UI và xóa test.
- OL `b33d653`: ngoài media còn sửa Lua `ol_mou/init.lua`, `xiaojie.lua`, `zhijiant.lua`; không coi commit có tiêu đề audio là asset-only.
- Overseas `fddc212`: thêm Ảo Từ Thịnh (`overseas_if`); phải phân loại mức tác động thật tới Quốc Chiến, không mặc định mọi tướng của repo đều vào pool.

## 2. Blocker đã tái hiện: chuyển Mưu Công sang Mobile

Commit Mobile [`ed18a9d8993a4678d30a0ddad87e1639017ab2c4`](https://gitee.com/qsgs-fans/mobile/commit/ed18a9d8993a4678d30a0ddad87e1639017ab2c4) mang tiêu đề chuyển Mưu Công sang Mobile. `mobile/pkg/mobile_mougong/init.lua` và `mougong/pkg/zhi/init.lua` cùng đăng ký `mou__daqiao`.

Đã xuất text runtime đúng target của cả 14 package vào `scratch/upstream-survey-20261019/runtime-text/`, sử dụng loader và host Lua/Wasmoon hiện tại của TQS, giữ compatibility repair khai báo Đoạn Ổi hiện có. `LuaRuntime.start()` **ném lỗi thật**:

```text
Duplicate general mou__daqiao detected[package exist mobile_mougong, new package mou_zhi ]
./ltk/core/engine.lua:245
```

Có thêm cảnh báo trùng target tip/QML mark trước lỗi. Việc khóa pack tại bước tạo phòng không giải quyết được lỗi này, vì lỗi phát sinh khi đăng ký package lúc khởi động, trước khi chọn mode/phòng.

**Chỉ khi chọn nâng Mobile:** phải audit chuyển gói/owner và xung đột registry. Theo scope hiện tại, mặc định giữ dependency pin cũ và nâng Hegemony riêng; hai hướng sau chỉ là phương án tham khảo nếu cần nâng Mobile, chưa chọn release:

1. **Chuyển sang Mobile làm owner Mưu Công:** có thể cần bỏ việc tải `mougong` độc lập, cập nhật manifest/installer/verifier/CI/QA từ tập 14 cũ sang tập mới. Phải kiểm đủ skill, ngữ nghĩa, translations, native/web parity và rollback; không xóa gói chỉ để làm test xanh.
2. **RC chuyển tiếp giữ Mobile cũ:** có thể giữ nguyên 14 repo để giảm phạm vi chuyển đổi trước mắt, nhưng phải ghi rõ các sửa luật/private mark Mobile bị hoãn và chứng minh tương thích với phần còn lại. Không được trình bày bản này là đã nâng toàn bộ upstream.

## 3. Bể tướng/bài thay đổi thật khi nạp Hegemony mới

Đã chạy probe baseline và các tổ hợp chẩn đoán; số tướng dưới đây lấy từ `Fk.generals`, lọc package bị mode vô hiệu và tướng hidden/total_hidden; pack/card count lấy trực tiếp `__web_room_packs('new_heg_mode')`.

| Chỉ số | Baseline pin hiện tại | Hegemony mới + dependency cũ (chẩn đoán) |
| --- | ---: | ---: |
| Tướng active/visible | 301 | 233 |
| `overseas_heg` | 76 | 5 |
| `mobile_heg` | 21 | 23 |
| `transformation` | 7 | 8 |
| `nine_variations` (số card trong pack do API trả về) | 54 | 52 |
| `lord_cards` (số card trong pack do API trả về) | 5 | 9 |
| Nhóm pack tướng/bài hiển thị | 14 / 4 | 14 / 4 |

Diff `hegemony/pkg/overseas_heg/init.lua` cho thấy upstream comment phần lớn các khai báo tướng, giải thích việc giảm 71 tướng trong pack này. Không tự mở lại các khối comment để duy trì số lượng cũ. Cần nghiệm thu thay đổi danh mục và policy khóa pack/pool thiếu tướng trước khi release.

`hegemony_nos` vẫn bị `Fk.game_mode_disabled.new_heg_mode` vô hiệu trong các tổ hợp đã khởi động thành công. Vì vậy, nhìn thấy file mới trong repo hoặc `extension.game_modes_whitelist` chưa đủ để kết luận tướng đó nằm trong pool hiện hành.

Lưu ý thuật ngữ kế hoạch cũ: **5/7/10 là số lá tướng được chia cho mỗi người** (`generalNum`), không phải ba cỡ phòng cần mặc định. Test pool phải kết hợp `capacity × generalNum`, whitelist và policy khóa pack thực tế.

## 4. Bằng chứng đã chạy trong lần khảo sát này

| Kiểm tra | Kết quả và giới hạn |
| --- | --- |
| `npm --prefix game/web run prepare:upstream -- --check` | PASS 14/14 checkout pin hiện tại, đúng SHA và clean |
| `npm --prefix game/web run test:upstream-preparation` | PASS 3/3 |
| `npm --prefix game/web run test:room-pools` | PASS 1/1 trên baseline cũ |
| `npm --prefix game/web run test:qa-server-contract` | PASS 44/44 trên baseline cũ; không phải C++ E2E của snapshot mới |
| Áp dụng nguyên đoạn repair/hardening của installer hiện tại vào bản sao core/hegemony mới | PASS; gồm Duan Wei, prelight idempotence, retained fake skill, owner/stale cleanup, khóa pack. Chỉ đoạn patch, chưa chạy toàn installer/DB/config/binary |
| `luac` 5.4 `-p` trên 4 file sau vá | PASS cú pháp; không chứng nhận behavior |
| Wasmoon baseline | START PASS, 301 active tướng |
| Wasmoon chỉ core mới + phần còn lại cũ | START PASS, 301 active, 0 tham chiếu skill active thiếu trong các collection đã duyệt |
| Wasmoon chỉ Hegemony mới + phần còn lại cũ | START PASS, 233 active, 0 tham chiếu skill active thiếu |
| Wasmoon toàn HEAD mới, giữ Mobile cũ (14 repo) | START PASS, 233 active, 0 tham chiếu skill active thiếu |
| Wasmoon toàn HEAD mới, bỏ tải `mougong` (13 repo, chỉ chẩn đoán) | START PASS, 233 active, 0 tham chiếu skill active thiếu |
| Wasmoon toàn HEAD mới, đủ 14 repo cũ | START **FAIL** do duplicate `mou__daqiao` |

Các tổ hợp mixed/13 repo trên chỉ giúp định vị nguyên nhân; chưa phải snapshot phát hành được duyệt. Kiểm “0 tham chiếu thiếu” duyệt `skills`, `other_skills`, `related_skills`, `related_other_skills`, `all_skills` của tướng trong package active; chưa kiểm mọi thân hàm skill, event, request hoặc effect.

Máy local là macOS. Có Lua **5.4.9** bên cạnh Lua mặc định **5.5.1**; thử interpreter 5.4 trực tiếp chưa load được `socket`/`lfs` với search path mặc định. Bootstrap source native hiện yêu cầu Linux/Debian/Ubuntu và toolchain/module riêng. Chưa kiểm preflight với runtime-local module tree, chưa kiểm máy Linux QA trong phiên này; không suy ra VM hiện tại thiếu module hoặc đã sẵn sàng build.

Không chạy build/release mới, native C++ server, E2E candidate, backup restore, device smoke hoặc thao tác hosted trong lần khảo sát. Root `dist/`, runtime, pin native/browser và các thay đổi build/pipeline đang dở được giữ nguyên.

## 5. Quyết định theo từng bước U0–U8

| Bước | Tính khả thi hiện tại | Việc bổ sung/điều kiện |
| --- | --- | --- |
| U0 | **Có thể bắt đầu** | Checkout hiện là `main@b8527d28`, khác mốc cũ; worktree build/CI đang dirty. Cô lập đúng source cần dùng, lưu identity live/baseline; chưa coi U0 hoàn tất |
| U1 | **Đã khảo sát một phần, có thể tiếp tục** | Full SHA/diff đã có; hoàn thiện ma trận dependency và P0 scenario chỉ cho Quốc Chiến |
| U2 | **Kiểm core đang pin; chỉ spike nâng nếu cần** | Đoạn patch áp dụng PASS; vẫn cần contract behavior, Lua modules, Linux QA và native worker phục vụ Hegemony đích |
| U3 | **Có hướng Hegemony mới + dependency cũ** | Probe START PASS; kiểm đầy đủ snapshot/owner/repair. Migration Mobile/Mưu Công chỉ mở nếu thực sự cần nâng Mobile |
| U4 | **Sau khi U3 giải quyết** | Browser/native cùng tập pin mới, media cập nhật, manifest/verifier cùng số package; dùng đúng output tách biệt |
| U5 | **Bắt buộc mở rộng** | Pool 301→233, overseas 76→5, card pool mới, GameOver sau đổi phe, private state và skill owner |
| U6 | **Sau U3–U5** | Baseline tests đang xanh chỉ làm mốc so sánh; phải chạy lại audits/regression/native E2E trên target đã chốt |
| U7 | **Chưa sẵn sàng** | Candidate cô lập sau local/native gates, endpoint/DB/port riêng và smoke đúng release identity |
| U8 | **Chưa sẵn sàng** | Rollback rehearsal native+web, thiết bị thật và G7 official chung; phát hành production là phạm vi riêng |

Thứ tự đề xuất: **U0 → U1 diff Hegemony/dependency thực dùng → U2 kiểm core hiện tại → U3 Hegemony mới + dependency giữ pin → U4–U6 trong scope Quốc Chiến → U7 → U8**. Chỉ mở nâng dependency khi có bằng chứng cần thiết. Không thêm cơ chế auto-update/auto-deploy. 14 repository runtime và 14 nhóm pack tướng là hai khái niệm khác nhau; không dùng một con số để sửa đồng loạt các assertion không cùng ý nghĩa.

## 6. Bằng chứng và lần tiếp tục

- Dữ liệu máy đọc: `scratch/upstream-survey-20261019/remote-heads.json`, `survey.json`, `*-files.tsv`, `*-since-17oct.txt`.
- Các probe có thể kiểm lại: `client-probe.ts`, `mixed-probe.ts`, `*-client-probe.json`, `patch-probe/run.sh`; bản sao source/objects chỉ dùng khảo sát, không phải release bundle hoặc backup độc lập.
- Kế hoạch gốc: [UPSTREAM_RELEASE_2026-10-17_PLAN.md](UPSTREAM_RELEASE_2026-10-17_PLAN.md). Đọc bổ sung khảo sát này trước khi giao U3/U5; không áp dụng giả định “giữ nguyên 14 HEAD là tương thích”.
- Bước tiếp theo có thể giao ngay: **triển khai U0**, sau đó hoàn thiện U1 theo Hegemony và dependency thực dùng, nghiệm thu danh mục tướng Quốc Chiến mới. Không bắt buộc chuyển Mưu Công khi giữ Mobile cũ. Không đánh dấu U0/U1/U2 đã nghiệm thu đầy đủ từ các probe giới hạn ở trên.
