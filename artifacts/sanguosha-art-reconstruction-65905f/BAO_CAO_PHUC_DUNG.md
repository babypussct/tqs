# Báo cáo phục dựng artwork Tam Quốc Sát

**Ngày thực hiện:** 28/10/2026 (Asia/Ho_Chi_Minh)
**Trạng thái:** Đã tạo PNG độc lập và kiểm tra bằng mắt; **chưa chứng nhận trùng khớp 100% với nguyên tác bị che**.

## Sản phẩm

- **Ảnh bàn giao:** `sanguosha-artwork-restored.png` — PNG RGB, **1061 × 1483 px**. Bức tranh không còn khung lá bài, bảng kỹ năng, tên tướng, chỉ số, dấu mờ/chữ hoặc icon giao diện nhìn thấy được.
- **Ảnh gốc:** `source-card.png` — PNG RGBA, 744 × 1040 px, tải từ:
  <https://i0.hdslb.com/bfs/album/65905f042bd078b05011c8e8227e15ca1672821212.png>
- **Phương án AI thuần:** `imagegen-candidate.png` — hình phục dựng bằng built-in ImageGen.
- **Mặt nạ bảo toàn:** `preservation-mask.png` — trắng: ưu tiên tranh nguồn; đen: phần tái tạo; vùng xám: chuyển tiếp.
- **Yêu cầu gốc nguyên văn:** `ORIGINAL_PROMPT.md`.

## Quy trình đã thực hiện

1. Lấy và lưu nguồn PNG. Đối chiếu trực quan cho thấy các thành phần che tranh: cột chữ/khung ở bên trái, năm chỉ số ở phía trên và hộp kỹ năng, chi tiết thẻ, chỉ số cùng credit ở vùng dưới.
2. Dùng công cụ built-in ImageGen, yêu cầu tái tạo phần tranh phía sau các lớp phủ theo phong cách, tư thế, màu sắc và vật thể hiện có. Không yêu cầu thay đổi nhân vật hoặc phát minh chi tiết mới.
3. Ghép lại bằng ảnh nguồn được phóng đúng tỷ lệ với bộ lọc LANCZOS, bảo toàn vùng minh họa rõ ràng và chuyển tiếp mềm ở ranh giới lớp che. Các tỷ lệ mask là **45,9%** vùng lấy trực tiếp từ ảnh nguồn đã phóng, **6,8%** vùng chuyển tiếp và **47,2%** vùng AI phải phục dựng. Đây là diện tích pixel trên kết quả; không phải thước đo độ chính xác so với nguyên tác.
4. Mở và kiểm tra trực quan bản cuối: không thấy chữ/tên tướng/chỉ số/khung/bảng kỹ năng; tay, quạt lông, khuôn mặt, mũ, áo choàng và tư thế chính có tính liên tục hợp lý. Không thực hiện nhận dạng chữ tự động để đưa ra lời bảo đảm tuyệt đối.

## Các vùng chưa thể xác minh với nguyên tác

- **Phía sau bảng tên dọc bên trái:** cây, núi, bầu trời và một phần áo choàng được suy luận từ bối cảnh quanh đó.
- **Phía sau năm ký hiệu ở phía trên:** bầu trời và các vật thể nhỏ như lá/chim được xây lại dựa trên vùng liền kề.
- **Hộp kỹ năng và toàn bộ vùng sát mép dưới:** thân dưới của áo choàng, dải lụa đỏ, mặt đất, đá và dòng nước là phần mở rộng suy luận. Mức độ chính xác chi tiết không thể xác thực chỉ bằng lá bài có lớp che.
- **Các vùng chuyển tiếp:** kỹ thuật ghép có thể tạo sai khác nhỏ ở nét cọ, chi tiết và ánh sáng sát ranh giới phục dựng.

Chưa tìm thấy bản artwork trần của **chính cùng tác phẩm** có thể kiểm chứng để dùng làm chuẩn cho các phần bị che. Vì vậy kết quả là bản phục dựng thị giác có giới hạn, chưa phải bản khôi phục có chứng cứ từng pixel cho toàn bộ bức tranh. Một số chi tiết suy luận có thể khác nguyên tác.

## Bảo toàn dữ liệu và môi trường

- Tất cả sản phẩm đặt trong một thư mục mới của repository `tqs`; không sửa mã game, asset đang dùng hoặc triển khai production.
- Ảnh nguồn SHA-256: `ece3292f72d7f3d4b16be39818189f029cafe0b03a200876ec69ec215f1f318f`.
- Ảnh bàn giao SHA-256: `eac8face7ce6840c618efd569bd3ed36acbff22140679137773f73860ec63a23`.
- Task Codex riêng đã được tạo trong project `tqs`, nhưng lượt đầu gặp lỗi khởi tạo thư mục làm việc và lượt tiếp theo gặp giới hạn sử dụng của phiên mới. Việc tạo PNG được hoàn tất bằng các công cụ Codex ở phiên điều phối hiện tại; trạng thái hai lượt chạy lỗi không được ghi thành công.
