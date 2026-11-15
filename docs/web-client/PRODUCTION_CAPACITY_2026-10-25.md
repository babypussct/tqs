# Xác minh RAM/CPU/disk production — 25/10/2026

**Đã SSH vào đúng máy đang phục vụ production**, alias `tqs-native-qa-replacement`, hostname `freekill-hegemony-qa`, shape lấy từ OCI instance metadata là `VM.Standard.E2.1.Micro`, kiến trúc `x86_64`. Probe bắt đầu **13:59:25 ngày 25/10/2026 giờ Việt Nam**. Toàn bộ thao tác remote chỉ đọc: tài nguyên `/proc`, filesystem metadata, service/listener, manifest gateway và kernel OOM metadata đã lọc; không đọc credential hoặc thay cấu hình/dịch vụ.

**Đính chính lượt trước:** alias `tqs-native-qa` trỏ VM cũ. Lỗi publickey trên alias đó không chứng minh không vào được production hiện tại. Alias replacement có sẵn trong SSH config và hồ sơ vận hành, đã kết nối được bằng key cấu hình sẵn; không thay key hoặc quyền truy cập.

## Số liệu đã quan sát

| Hạng mục | Kết quả |
| --- | --- |
| CPU hiển thị trong guest | **2 logical vCPU**, model `AMD EPYC 7551 32-Core Processor`; không suy từ tên model rằng VM có 32 core, hoặc 2 logical CPU là 2 core dành riêng |
| Load average | **0,00 / 0,023 / 0,00** tại thời điểm probe |
| CPU mẫu 10 giây | **99,85% idle**, 0,05% user, 0,10% iowait, 0% steal trong cửa sổ đo |
| RAM tổng | **954 MiB** (`1.000.341.504` byte) |
| RAM khả dụng | **397,9 MiB** (`417.263.616` byte, `MemAvailable`, đã tính phần cache có thể thu hồi) |
| Swap | Tổng **2.048 MiB**, đang dùng **272,4 MiB** |
| Disk filesystem `/` và runtime | ext4, usable tổng **44,07 GiB**, available **18,48 GiB**; `df -h` làm tròn 45G/19G, dùng 59% |
| Inode | Tổng 5.980.160, còn 5.470.625; khoảng **9% đã dùng** |
| Memory pressure | PSI memory `some/full avg10/60/300 = 0` trong snapshot; không chứng minh an toàn khi có nhiều phòng hoặc build |
| Swap/OOM trong mẫu 10 giây | Swap-in 3 page, swap-out 0; **0 OOM mới** |
| OOM lịch sử boot hiện tại | Counter `oom_kill=1`; kernel journal ghi **`cc1plus` bị kill ngày 16/10 lúc 11:26:26 giờ Việt Nam**, không phải sự cố mới ngày 25/10 |

Không chạy benchmark/stress hoặc tạo phòng để đo tải. Đây là snapshot production đang tải thấp, không phải capacity tối đa hoặc chứng nhận hai server chạy ổn định đồng thời.

## Bộ nhớ tiến trình production

| Tiến trình | Resident RAM (RSS) | Swap của tiến trình |
| --- | ---: | ---: |
| Native C++ `MainThread` | 10,3 MiB | 3,7 MiB |
| Lua worker `lua5.4` | 124,4 MiB | 11,1 MiB |
| Gateway `node` | 41,2 MiB | 102,2 MiB |
| Tunnel `cloudflared` | 22,8 MiB | 2,7 MiB |

RSS cộng thô khoảng 198,7 MiB, có thể trùng shared pages; evidence có PSS để tham khảo. Không cộng swap vào RSS và gọi là resident. Gateway systemd `MemoryPeak` khoảng 163,5 MiB; memory service hiện khoảng 45,3 MiB. Native unit là oneshot `active/exited`, trong khi native/Lua thực tế đang sống trong tmux/session scope; không lấy `MemoryCurrent=[not set]` của unit làm 0 RAM.

Root cgroup không có các file `cpu.max`/`memory.max`/`memory.swap.max` trong probe; không suy đây là không giới hạn ở mọi cấp. Chưa audit quota toàn bộ cgroup hierarchy hoặc hạn mức nhà cung cấp. Không cần thay quota để thực hiện nhiệm vụ xác minh này.

## Xác nhận đúng production và tình trạng dịch vụ

- Runtime/process cwd: `/opt/freekill-hegemony/releases/ai-prompt4-20261022-prod-clean`; symlink `current` trỏ cùng release.
- `freekill-native`, `tqs-gateway`, `tqs-quick-tunnel`: **active**. Listener game `9527`, admin `9000`, gateway loopback `8080` đều hiện diện.
- Manifest gateway nội bộ `127.0.0.1:8080` và public `tqsvn.pages.dev/gateway/manifest.json` khớp **MD5 `845498010a0c9f790254ec86e3dfc999`, bundleHash `5beabc83feac2d67`, fileCount 5281**.
- Public manifest và health **HTTP 200**, health body `ok`. Không kiểm authenticated gameplay trong nhiệm vụ tài nguyên.

## Kết luận cho kế hoạch chạy song song

**CPU hiện rảnh và disk còn dung lượng; RAM là ràng buộc chính.** Khoảng 398 MiB khả dụng với swap đang dùng không đủ bằng chứng để chấp nhận thêm một production instance hoặc build native cạnh live mà không ảnh hưởng người chơi. Swap đang dùng có thể là page lạnh từ tải trước; không kết luận máy đang thrash khi mẫu mới không có swap-out và PSI memory bằng 0.

1. Giữ production hiện tại; build native trên môi trường khác có RAM đủ rồi chuyển artifact đã verify. OOM `cc1plus` lịch sử là bằng chứng thực tế không nên đặt full native build trên VM 1 GiB đang phục vụ live.
2. Ưu tiên candidate trên máy/môi trường riêng. Chưa tạo hoặc mua VM, nâng shape hoặc bật dịch vụ trong nhiệm vụ này.
3. Nếu chọn cùng host, chỉ bắt đầu bằng QA bounded có giới hạn CPU/RAM/PID/room, đầy đủ network namespace/DB/root riêng; theo dõi `MemAvailable`, swap, PSI, health và latency production. Chưa chốt memory budget cụ thể hoặc tuyên bố parallel runtime PASS từ snapshot hiện tại.
4. Disk available 18,48 GiB là dung lượng hiện tại, chưa phải ngân sách đã trừ candidate, source/build, backup và restore rehearsal. Lượt `du` ưu tiên thấp để phân rã releases/backups/source/QA dừng do timeout 20 giây; không dùng số liệu phân rã chưa thu được để quyết định xóa dữ liệu.

Evidence local: `scratch/production-capacity-20261025/{probe.py,inspection.json,oom-summary.json,public-manifest.json,health.txt}`. Probe SSH/sudo read-only **PASS**, local/public identity assertions **PASS**; disk breakdown timeout được giữ rõ trong JSON. Không restart, stop, deploy, đổi KV/DNS/DB, thêm swap hoặc dọn file production.
