# Rà soát kế hoạch nâng upstream Quốc Chiến — 25/10/2026

> **Phương án triển khai hiện hành:** [UPSTREAM_INCREMENTAL_PLAN_2026-10-25.md](UPSTREAM_INCREMENTAL_PLAN_2026-10-25.md): giữ production, nâng/test từng phần ngoài live; không dựng thêm native thường trực trên VM 1 GiB. Phương án song song được khảo sát dưới đây là lịch sử, giữ phần kỹ thuật có liên quan.

> **Bổ sung theo yêu cầu tiếp theo:** production cũ tiếp tục chạy khi nâng, candidate độc lập và chỉ bỏ bản cũ sau promote/kiểm ổn định. Kiểm source, public identity và trình tự thực hiện tại [UPSTREAM_PARALLEL_CUTOVER_2026-10-25.md](UPSTREAM_PARALLEL_CUTOVER_2026-10-25.md).

**Kết luận:** mục tiêu upstream không đổi so với khảo sát 19/10. `master` của [qsgs-fans/hegemony](https://gitee.com/qsgs-fans/hegemony) vẫn là `d069cd1f5c6df8d93af0ea101b82a5bed2781f01`; TQS vẫn pin `d616978ad2a53055f5815f3ae19f2d2b239862e0`. Còn **7 commit**, **194 tệp**, **4.841 dòng thêm / 1.386 dòng xóa**. Chưa thực hiện nâng pin U3 hoặc nghiệm thu native trên target mới. Tiếp tục U0–U8 với bổ sung bảo toàn các bản vá TQS phát sinh sau kế hoạch cũ.

Phạm vi là `new_heg_mode`, cùng core/utility/skill/card/helper thực sự phục vụ Quốc Chiến. Không nâng đồng loạt các dependency hoặc mở thêm mode/Shop. Phiên này rà soát source, remote, kế hoạch và chạy kiểm local; không build candidate, truy cập máy production hoặc phát hành.

## 1. Đối chiếu thực tế ngày 25/10

| Nội dung | Kết quả đã quan sát trong phiên |
| --- | --- |
| Source TQS | `main@936f3f8c953a85c51179988efbf1969e35623179`; có sẵn 5 tệp dirty thuộc system update/PWA, được giữ nguyên |
| Pin native/browser | Hegemony `d616978ad2a53055f5815f3ae19f2d2b239862e0`; đối chiếu đủ 14/14 package SHA giữa `versions.env` và `UPSTREAM_PACKAGES` |
| Remote hiện tại | `git ls-remote --symref … HEAD refs/heads/* refs/tags/*`: HEAD → `master` → `d069cd1f5c6df8d93af0ea101b82a5bed2781f01`; không có branch/tag khác được trả về |
| Đối chiếu API | [Gitee branch API](https://gitee.com/api/v5/repos/qsgs-fans/hegemony/branches/master) trả cùng SHA; commit cuối ngày 19/10/2026 09:04:07 giờ Việt Nam, thêm Quốc Chiến Mobile Từ Thứ/Bành Dạng |
| Từ khảo sát 19/10 đến nay | **0 commit mới** trong nhánh vừa xác minh; không suy rộng sang các repo dependency chưa đọc lại HEAD trong phiên này |
| Ancestry và source cache | Pin là ancestor của target; xác minh hash Git blob của **527 tệp text** Hegemony cache theo tree của target, **0 mismatch** |
| Thành phần diff 194 tệp | **98 Lua, 5 QML, 48 MP3, 16 PNG, 27 JPG**; không dùng tiêu đề commit để kết luận asset-only hoặc ngoài scope |

Lượt API đầu thành công HTTP 200 và đã đọc trực tiếp output; hai lượt thu lại response để lưu file bị read/SSL timeout. Evidence API lưu các trường đã quan sát, có nhãn bản ghi từ output thay vì raw response. Remote Git đọc được target; lỗi truy cập bằng web reader không phải blocker nâng cấp. Source cache chỉ dùng cho khảo sát/probe, không thay checkout pin chuẩn và không phải artifact phát hành.

## 2. Bảy commit còn thiếu so với pin TQS

| Commit | Thay đổi upstream cần phân tích/test |
| --- | --- |
| `62d8fa99f998967baf142fb2d82fd25cc16ace31` | Số lượng bài Cửu Biến, Tả Từ |
| `1e2b8b51ebb6d0f8cd2812530e6a026cd97cde27` | Mobile quân chủ Tào Phi, Lưu Thiện, Tôn Sách, Đổng Trác |
| `20edcb993bedf301157496d575b1e45cc434dce0` | Sửa audio; đánh giá trạng thái cuối sau revert kế tiếp |
| `8acef2ff25e134733e47de73b60a043583e017c4` | Revert; dùng diff pin→target làm đầu vào, không đếm thành hai tính năng độc lập |
| `849f3210c6ae08e3faa5dc5e6999625bc449dc6b` | Quốc Chiến 27 Điển Tàng: Chu Linh, Lưu Ba, Ngô Cảnh, Nghiêm Bạch Hổ, Mạnh Đạt, Trương Lỗ, Mi Phương/Phó Sĩ Nhân, Lưu Kỳ, Đường Tư, Văn Khâm |
| `c12ee337650fba96e65eaf3c4277895119587c1c` | Quốc Chiến 27 Trân Tàng: Gia Cát Khác, Tô Phi, Hứa Du, Bành Dạng, Tôn Lâm và bốn trang bị chuyên dụng |
| `d069cd1f5c6df8d93af0ea101b82a5bed2781f01` | Mobile Quốc Chiến Từ Thứ/Bành Dạng |

Các commit, danh sách tệp và thống kê được đọc lại từ Git trong phiên này. Danh sách trên là inventory theo commit; U1/U5 còn phải ánh xạ từng delta luật cuối cùng sang scenario và nội dung thực sự bật trong mode.

## 3. Probe lại bằng client hiện tại

Dùng `LuaRuntime` hiện tại, `loadUpstreamFiles` và declaration repair hiện hành; thay riêng text Hegemony bằng target đã kiểm hash, giữ 13 dependency pin. Đây là probe source upstream có repair, **không phải runtime production đã áp đủ patch TQS**, không chạy C++ server hoặc thân hàm effect của mọi skill.

| Chỉ số | Pin hiện tại | Hegemony target + dependency giữ pin |
| --- | ---: | ---: |
| Khởi động Wasmoon | PASS | PASS |
| Active/visible generals trong registry mode | 301 | 233 |
| `overseas_heg` | 76 | 5 |
| `mobile_heg` | 21 | 23 |
| `transformation` | 7 | 8 |
| `nine_variations` (API card count) | 54 | 52 |
| `lord_cards` (API card count) | 5 | 9 |
| Nhóm tướng / nhóm bài | 14 / 4 | 14 / 4 |
| Tham chiếu skill active thiếu trong collection đã duyệt | 0 | 0 |
| Warning/error lúc khởi động | 0 | 0 |

`hegemony_nos` vẫn bị mode vô hiệu. **301/233 là inventory active/visible của registry**, khác số general pile sau policy, hidden/deputy-only và filter server; test room-pools hiện tại báo general pile 241 trước khi khóa pack, không mâu thuẫn và không được thay thế hai đại lượng cho nhau. 5/7/10 là `generalNum` mỗi người; kiểm capacity × generalNum × policy khóa pack.

Không tự uncomment các tướng overseas upstream đã vô hiệu để giữ 301 tướng. Sự giảm danh mục là thay đổi sản phẩm bắt buộc phải ghi nhận ở U5, cùng thiếu pool/cặp hợp lệ khi kết hợp policy và số ghế. Lỗi Mobile/Mưu Công trong khảo sát 19/10 vẫn chỉ là **báo cáo trước** của tổ hợp nâng đồng loạt; không phải blocker mặc định khi giữ Mobile cũ.

## 4. Bổ sung kế hoạch do TQS đã thay đổi từ 19/10

**U0 phải đóng băng cả pin và patch sau pin.** So text runtime hiện tại với checkout upstream pin sạch cho thấy **24 tệp core**, **11 tệp Hegemony**, **0 tệp utility** khác/thêm. Đây là kiểm kê file, chưa phải 35 bản vá độc lập hoặc toàn bộ overlay của 14 repo. U1 cần mở rộng inventory sang mọi package thực dùng, nhận diện file bị xóa và dựng diff ba phía `upstream pin → TQS runtime → upstream target`.

- Core có SmartAI/dispatcher, faction inference, chọn cặp tướng, request adapters, server room/player, fake-skill/prelight và các auxiliary skill. Hegemony có `util.lua`, AI theo skill, Tử Gián `sijian.lua` và declaration repair overseas.
- Trong 11 tệp Hegemony khác pin, **`util.lua` và `pkg/overseas_heg/init.lua` cùng bị upstream target sửa**. Cần merge theo ngữ cảnh và test riêng; 9 tệp còn lại vẫn phải bảo toàn dù không nằm trong incoming diff. Giữ ranh giới luật/effect, AI và QA; không copy đè nguyên file cũ lên upstream mới.
- U2/U3 bổ sung bảng mỗi hunk: nguồn/lý do → còn cần hay upstream đã sửa → cách giữ/port/bỏ → bài kiểm bắt buộc. Kiểm cả repair `langmie` trong phần overseas bị comment: string repair khớp không chứng minh tướng đó vẫn active.
- Native source có patch quản lý account-temp-ban/reconnect, compiler compatibility và TQS ticket/access. Nếu giữ native SHA vẫn phải tái tạo và kiểm behavior bản binary có patch; không dùng static binary chưa vá thay cho source release hiện hành. Không suy từ source-managed code PASS ra production đã áp đầy đủ mọi patch mới.
- U4 đồng bộ Lua/asset/audio/bản dịch và manifest/flist/service worker; bảo toàn các thay đổi UI/select pair/Google OAuth/system update hiện hành. Kiểm semantic bản dịch của key mới/sửa, không chỉ placeholder. Báo cáo trước ngày 24/10 về queue 4.843 key vẫn có semantic review mở.
- U5/U6 chạy lại bằng **snapshot mới sau port**: SmartAI bounded/native regression, hidden/prelight/owner, Tử Gián, Kỳ Sách/Dũng Tiến, chọn chủ/phó, bài/kỹ năng, GameOver và reconnect. Evidence AI/UI đã có trên pin cũ là baseline tham khảo; không chuyển PASS sang target mới.
- Với core giữ pin: vẫn phân tích lỗi GameOver khi đổi identity đã được ghi trong khảo sát core 19/10 (`1fd47a16`). Quyết định giữ/nâng/backport chỉ sau test chứng minh tác động Quốc Chiến; không ghi đây là tính năng tự có chỉ vì nâng Hegemony.
- Thiết bị iOS/Android và physical-network đã có **`WAIVED_BY_USER` trong bàn giao 23/10**. Kế hoạch này mang tiếp trạng thái đó, không tự đưa lại thành blocker bắt buộc và không ghi PASS. Browser/mobile viewport và reconnect tự động vẫn phải kiểm; thiếu coverage thiết bị phải ghi rõ trong nghiệm thu.

## 5. Trạng thái U0–U8 sau rà soát

| Gate | Trạng thái thực tế | Việc cần hoàn tất |
| --- | --- | --- |
| U0 | OPEN; đã đọc source/pin/dirty hiện tại | Baseline tái tạo trong môi trường riêng, đầy đủ patch/runtime/native/web identity; identity production mới chỉ là báo cáo trước |
| U1 | PARTIAL | HEAD/diff Hegemony xác minh lại; còn graph phụ thuộc, diff ba phía đầy đủ, quyết định từng delta và ma trận scenario |
| U2 | PARTIAL | Probe START/registry PASS; còn behavior/effect, native worker, tương thích patch và quyết định giữ/nâng từng repo có lý do |
| U3 | CHƯA ÁP DỤNG | Chốt snapshot, port patch và đồng bộ pin native/browser/QA ở nhánh thử |
| U4 | CHƯA CHẠY trên target mới | Build/verify native và web, hash/manifest/flist/registry/media parity |
| U5 | OPEN | 100% delta P0 luật/privacy có scenario; nghiệm thu danh mục 301→233 và pool thực tế |
| U6 | OPEN | Regression và C++ E2E bot/hai người, request/skill, GameOver, reconnect trên đúng target sau patch |
| U7 | CHƯA SẴN SÀNG | Candidate cô lập sau U0–U6; coverage điện thoại giữ trạng thái waiver/giới hạn |
| U8 | CHƯA SẴN SÀNG | Restore/rollback native+web cùng identity, điều kiện vận hành và chỉ thị phát hành riêng |

Các lần UI/AI/production/CI PASS gần đây được ghi trong `CODEX_STATE.md` trên baseline pin cũ. Chúng không đóng U3–U8. Các câu “chưa deploy”, “production NO-GO” trong checkpoint lịch sử phải đọc theo ticket/identity tại thời điểm đó; không phủ nhận những phát hành baseline đã diễn ra sau này.

## 6. Kiểm chứng và evidence của phiên

| Lệnh/kiểm tra | Kết quả đã quan sát |
| --- | --- |
| Git remote + API Gitee master | Cùng target `d069cd1`; 0 delta từ khảo sát 19/10 |
| Git ancestry/count/diff, hash cache target | PASS; 7 commit, 194 tệp; 527 text blob khớp |
| Đối chiếu pin native/browser | PASS 14/14 |
| `npm --prefix game/web run prepare:upstream -- --check` | PASS 14/14 checkout pin sạch |
| `npm --prefix game/web run test:upstream-preparation` | PASS 3/3 |
| `npm --prefix game/web run test:room-pools` | PASS 1/1 trên baseline pin cũ |
| `npm --prefix game/web run test:qa-server-contract` | PASS 52/52 trên contract hiện tại; không phải native candidate gameplay |
| `tsx scratch/upstream-review-20261025/hegemony-scope-probe.ts` | Baseline và Hegemony-only START PASS, 0 missing active refs/warning/error; không phải nghiệm thu native effect |

Evidence local: `scratch/upstream-review-20261025/` gồm `review.json`, `master-api-observation.json`, `hegemony-files.tsv`, `runtime-overlay-inventory.json`, `hegemony-scope-probe.ts`, `probe.log`, hai `*-client-probe.json` và `server-contract.log`. Source cache và objects: `scratch/upstream-survey-20261019/`; không xem là release/backup độc lập. Không đọc credential hoặc `.env` trong nhiệm vụ này.

**Bước tiếp theo:** triển khai U0 từ source hiện tại và runtime có patch, sau đó hoàn thiện U1/U2 để chốt **Hegemony `d069cd1` + dependency giữ pin trừ phần có bằng chứng cần đổi**. Bản tổng kết giao việc: [UPSTREAM_IMPLEMENTATION_SUMMARY.md](UPSTREAM_IMPLEMENTATION_SUMMARY.md); chi tiết gate: [UPSTREAM_RELEASE_2026-10-17_PLAN.md](UPSTREAM_RELEASE_2026-10-17_PLAN.md). Rà soát này chưa thực hiện U0 đầy đủ hoặc cấp quyền push/deploy.
