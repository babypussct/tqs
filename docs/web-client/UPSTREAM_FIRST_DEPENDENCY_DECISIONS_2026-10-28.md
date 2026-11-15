# Upstream-first — dependency và native decisions (28/10/2026)

Tài liệu này ghi quyết định Phase A theo full SHA. Các quyết định có chữ **provisional** chỉ là đầu vào để dựng candidate cô lập; chưa được hiểu là thay đổi pin, phát hành hoặc cho phép dùng production.

## Package snapshot

### Read-only revalidation 14/11/2026

The remote `freekill-core` `master` was revalidated without moving the working checkout: it is now `0010a2f4035d6b49d098a120bb754d8cd5252b0a`, with **18 commits / 36 files / +454/-253** relative to the candidate API floor `3c40e0f8dc54608a3b862c0cfcad80e5e61f5e02`. The observed delta includes QML/package-management/UI changes and later core behavior changes; it is not evidence that the Quốc Chiến candidate needs the floating master. The candidate remains on the exact floor until a `new_heg_mode` effect/API scenario proves a higher core revision is required. `versions.env` was not changed.

| Package | Pin hiện tại | Candidate decision | Lý do / kiểm chứng bắt buộc |
| --- | --- | --- | --- |
| `freekill-core` | `ade837d74c616dbd2d169934b0bec4a5a5dc0a85` | **Nâng tối thiểu provisional** tới API floor `3c40e0f8dc54608a3b862c0cfcad80e5e61f5e02` | Target Hegemony gọi `UseCardData:setDisresponsive()`; exact candidate phải được build, registry và native request/effect test. Core master `19200891…` không được dùng floating. |
| `gamemode` | `cf168265c56dd262ae79497cf71d55285bca4bb8` | Giữ pin | Chưa có delta target được chứng minh là cần cho `new_heg_mode`; kiểm room/mode registry sau khi dựng candidate. |
| `hegemony` | `d616978ad2a53055f5815f3ae19f2d2b239862e0` | **Chọn target provisional** `e8d93acd34a357f96b0105aef7d661708c211626` | Đây là `master` full SHA mới nhất quan sát được; parent `d069cd1…`, nhưng pin→target thực tế là 8 commit / 204 tệp / +4.893/-1.464 (113 source text, 91 binary). Delta 14 Lua là chỉ phần commit cuối. Cần retarget 43 inventory lịch sử + extra runtime overlay và test Quốc Chiến. |
| `jsrg` | `36201e75a6afc2a6f35a96bb07f4cd9a8a983193` | Giữ pin | Không có yêu cầu API từ delta Hegemony; chỉ nâng nếu registry/scenario chứng minh cần. |
| `mobile` | `dcd523cc887e5bd010b26b7450486ab26f54d5ac` | Giữ pin | Delta có `mobile_heg` nhưng không đổi source `mobile`; kiểm pool/identity khi target được nạp. |
| `mougong` | `2ce058ec5aaceda4ebe3517278612a3d41e26045` | Giữ pin | Ngoài delta target trực tiếp; giữ để giảm phạm vi. |
| `ol` | `ceee01b97dfc0b01eae27e6d5f2fabf6ead46413` | Giữ pin; media sparse vẫn OPEN | Không tự kéo 2.925 media sparse; chỉ mở khi Quốc Chiến target cần asset. |
| `overseas` | `6780626a34f9fdafa25e15772b9f0609c62c7999` | Giữ pin | Overlay `overseas_heg/init.lua` vẫn cần hunk review; chưa chứng minh dependency mới. |
| `shzl` | `a6743be11ac36db4efb57c5c2546102e2be805a0` | Giữ pin | 5 overlay AI/skill giữ nguyên theo ledger, native proof còn mở. |
| `sp` | `ab42a3fbba1e15e424b942e29ac8e0157c7086fc` | Giữ pin | Không có delta target trực tiếp. |
| `standard_ex` | `b041d9d4151d436bb6c357f7b772fa2f1a040df0` | Giữ pin | Không có delta target trực tiếp. |
| `tenyear` | `91a769c87f48006cce3e1ded90e4a1beb028f7ad` | Giữ pin | Hegemony `tenyear_heg` thay đổi không đồng nghĩa nâng package `tenyear`; cần scenario riêng. |
| `utility` | `f86d3d05b5a6835584323e56ab85db1fd87ddacf` | Giữ pin | Không có API requirement được chứng minh. |
| `yj` | `10edd0f42f492eaeece5de14a6ef19aa14560cd0` | Giữ pin | Không có delta target trực tiếp. |

### Quy tắc áp dụng

1. Không sửa `deploy/freekill-native/versions.env` trong Phase A. Khi dựng candidate, ghi một manifest mới với exact SHA và kiểm `prepare:upstream` trước audit/build.
2. Nếu core floor `3c40e0f8…` không đủ cho bất kỳ delta P0/P1 nào, quay lại decision và chọn một SHA cụ thể cao hơn; không tự lấy `master`.
3. Không coi compile/link PASS hoặc package registry PASS là gameplay parity. Mọi delta dùng API mới phải có native effect/state proof và browser projection proof trước U5.

## Native decision

| Hạng mục | Identity / quyết định |
| --- | --- |
| Native production hiện tại | Source pin `b8a2ad48305aea7b55ccca325fcbeb100cb8a01a`; binary SHA-256 `080b2d14e1e7840275ae431ae2474c679ff904a3351baf242c188d78c5bcf14b` |
| Reuse binary | **Chưa chấp nhận** cho target mới. Binary hiện tại được build từ core/Hegemony runtime cũ và chưa chứng minh API/behavior parity với target `e8d93a…`. |
| Build candidate | Build Linux x86_64 trong môi trường cô lập, ngoài VM production 954 MiB; ghi compiler, CMake, Boost, spdlog, source SHA, patch digest và binary hash. Ưu tiên tái tạo toolchain production; nếu hash khác, kiểm chức năng chứ không sửa manifest bằng tay. |
| QA topology | Native candidate, gateway, packages, DB, ticket secret và port/quota riêng; không dùng `current`, DB live hoặc service production. |
| Acceptance tối thiểu | Server startup, locked package/registry, `new_heg_mode`, pool/capacity, hidden main/deputy, reveal/re-hide, `removeGeneral`, YiGui, GameOver, reconnect và privacy. |
| Trạng thái | `PROVISIONAL — isolated build/boot/bounded E2E PASS; full native effect/privacy/reconnect acceptance OPEN` |

Evidence candidate: [`candidate-native-build-20261028.json`](../../scratch/evidence/upstream-first-a-20261028/candidate-native-build-20261028.json), [`candidate-native-boot-20261028.json`](../../scratch/evidence/upstream-first-a-20261028/candidate-native-boot-20261028.json), [`candidate-draw-sequence-summary-20261028.json`](../../scratch/evidence/upstream-first-a-20261028/candidate-draw-sequence-summary-20261028.json). Binary hash khác production chỉ ghi nhận khác toolchain/source candidate; không được suy ra parity hoặc release.

## Restore decision

Backup/SQLite rehearsal trước đó đã đạt archive byte-hash và SQLite integrity, nhưng restore có symlink tùy chọn `packages/freekill-core/qa_packages` bị dangling. Chính sách là coi `qa_packages` là QA-only optional mount: production restore phải giữ `tqsQa.enabled=false`, không tự trỏ symlink vào đường dẫn không xác minh, và phải có preflight/startup bounded chứng minh runtime production khởi động trong root restore đã chuẩn hóa. Backup gốc không được sửa/xóa trong Phase A.
