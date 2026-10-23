# Kế hoạch rà soát Việt hóa Quốc Chiến — danh sách thao tác

Sinh lại bằng `npm --prefix game/web run audit:translations`. Mở [CSV phân công](HEGEMONY_VIETNAMESE_WORK_QUEUE.csv) để lọc nhóm, điền `proposed_vi` và `review`; giữ nguyên `key`, placeholder `%...`, HTML và nguồn gốc. Bản [JSON đầy đủ](VIETNAMESE_GAP_INVENTORY.json) có cả các gói ngoài Quốc Chiến.

Cơ sở: **60,217 key** scan, **44,355** mục cần rà trên toàn runtime; tập bảo thủ Quốc Chiến/core/dependency có **4,843** dòng. Phân nhóm công việc: **P0 1820**, **P1 629**, **P2 2394**. Đây là công việc cần *duyệt*, chưa phải số lỗi hiển thị được chứng minh.

| Nhóm | Số dòng | Công việc kiểm tra |
| --- | ---: | --- |
| card_description | 27 | P0_GAMEPLAY_REVIEW |
| card_name_prompt | 71 | P0_GAMEPLAY_REVIEW |
| choice_ui_other | 464 | P1_DIALOG_REVIEW |
| general_name_title | 471 | P2_NAMES_VOICE_REVIEW |
| log_event | 43 | P0_GAMEPLAY_REVIEW |
| mark_counter | 165 | P1_DIALOG_REVIEW |
| skill_description | 275 | P0_GAMEPLAY_REVIEW |
| skill_name_generated | 149 | P0_GAMEPLAY_REVIEW |
| skill_prompt | 1255 | P0_GAMEPLAY_REVIEW |
| voice_death | 1923 | P2_NAMES_VOICE_REVIEW |

## Quy trình kiểm tra trước khi dịch

1. Ưu tiên mô tả lá bài (`card_description`), mô tả kỹ năng (`skill_description`), yêu cầu/chọn kỹ năng (`skill_prompt`) và tên kỹ năng phát sinh (`skill_name_generated`). Kiểm tra key có thực sự được React hoặc Lua UI gọi trong `new_heg_mode` hay không.
2. `contains_chinese`: duyệt dịch theo ngữ nghĩa từ nguồn Trung; `missing_or_raw`: phân biệt key nội bộ/placeholder và yêu cầu thực. `not_exported_to_react` chỉ là *khả năng* thiếu đường xuất sang React; cần xem code render trước khi kết luận.
3. `#1`, `#10`, `#0598BC` và các mã số/màu tương tự là literal, đã đánh dấu `literal_not_translation_key` trong CSV; tránh dịch thành văn bản. Các dấu `%arg`, `%from`, `<b>` hoặc tên key phát sinh giữ đúng cú pháp.
4. `voice_death`/tên tướng có trong file để không bỏ sót nhưng là P2. Kết quả scan tĩnh bao gồm kỹ năng của gói phụ và các khóa không tới được từ một trận Quốc Chiến; phải đối chiếu browser/native scenario. Key ghép động và server log sau expand cần quan sát bổ sung.
5. Khi duyệt bản dịch kỹ năng/tướng theo nguồn ngoài runtime, dùng Moegirl làm nguồn xác minh chính thống; không thay cơ chế hoặc luật C++/Lua.
