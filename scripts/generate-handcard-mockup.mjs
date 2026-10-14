import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const cardDefs = [
  { id: "ice__slash", name: "Băng Sát", suit: "♠", rank: "8", color: "suit-black", cat: "Cơ Bản", type: "type-basic", desc: "Tấn công 1 mục tiêu: Ngăn sát thương để bỏ 2 lá của mục tiêu.", file: "runtime/packages/gamemode/image/card/ice__slash.png" },
  { id: "v33__ex_nihilo", name: "Vô Trung Sinh Hữu", suit: "♥", rank: "7", color: "suit-red", cat: "Cẩm Nang", type: "type-trick", desc: "Sử dụng trong lượt ra bài: Rút ngay 2 lá bài từ chồng bài.", file: "runtime/packages/gamemode/image/card/v33__ex_nihilo.png" },
  { id: "ex_eight_diagram", name: "Bát Quái Trận", suit: "♣", rank: "2", color: "suit-black", cat: "Phòng Cụ", type: "type-equip", desc: "Mỗi khi cần ra Thiểm, có thể phán xét: Nếu là bài đỏ tính như đã ra Thiểm.", file: "runtime/packages/mobile/image/card/ex_eight_diagram.png" },
  { id: "ex_crossbow", name: "Nỏ Liên Châu", suit: "♦", rank: "A", color: "suit-red", cat: "Vũ Khí", type: "type-equip", desc: "Vũ khí tầm 1: Trong giai đoạn ra bài, bạn có thể ra vô hạn lá Sát.", file: "runtime/packages/mobile/image/card/ex_crossbow.png" },
  { id: "thunder_blade", name: "Lôi Đình Nhận", suit: "♠", rank: "5", color: "suit-black", cat: "Vũ Khí", type: "type-equip", desc: "Vũ khí tầm 3: Khi bạn dùng Sát, có thể chuyển thành Sát Sấm Sét.", file: "runtime/packages/tenyear/image/card/thunder_blade.png" },
  { id: "ex_vine", name: "Đằng Giáp", suit: "♠", rank: "2", color: "suit-black", cat: "Phòng Cụ", type: "type-equip", desc: "Phòng Cụ: Miễn nhiễm Sát thường, Nam Man, Vạn Tiễn; nhưng chịu +1 sát thương hỏa.", file: "runtime/packages/mobile/image/card/ex_vine.png" },
  { id: "ex_silver_lion", name: "Bạch Ngân Sư Tử", suit: "♣", rank: "A", color: "suit-black", cat: "Phòng Cụ", type: "type-equip", desc: "Phòng Cụ: Mỗi lần chỉ chịu tối đa 1 sát thương; khi mất trang bị này thì hồi 1 máu.", file: "runtime/packages/mobile/image/card/ex_silver_lion.png" },
  { id: "stab__slash", name: "Thích Sát", suit: "♦", rank: "9", color: "suit-red", cat: "Cơ Bản", type: "type-basic", desc: "Tấn công 1 mục tiêu: Mục tiêu phải dùng 2 lá Thiểm mới hóa giải được.", file: "runtime/packages/gamemode/image/card/stab__slash.png" },
  { id: "role__wooden_ox", name: "Mộc Ngưu Lưu Mã", suit: "♦", rank: "5", color: "suit-red", cat: "Bảo Vật", type: "type-equip", desc: "Bảo Vật: Có thể chuyển bài vào trong Mộc Ngưu để giấu hoặc truyền cho đồng đội.", file: "runtime/packages/standard_ex/image/card/role__wooden_ox.png" },
  { id: "v11__dismantlement", name: "Quá Hà Sách Kiều", suit: "♠", rank: "3", color: "suit-black", cat: "Cẩm Nang", type: "type-trick", desc: "Hủy 1 lá bài bất kỳ trên tay, vùng trang bị hoặc phán xét của một người chơi khác.", file: "runtime/packages/gamemode/image/card/v11__dismantlement.png" },
];

const cardsWithBase64 = cardDefs.map(c => {
  const buf = fs.readFileSync(path.join(repo, c.file));
  const b64 = "data:image/png;base64," + buf.toString("base64");
  return { ...c, b64 };
});

const cardsJson = JSON.stringify(cardsWithBase64);

const html = `<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Mockup Vùng Tay Bài Tam Quốc Sát: Thanh Ngang Thẳng Đứng 0° (FreeKill &amp; QSanguosha &amp; Mobile)</title>
<style>
  :root {
    --bg-wood-dark: #120e0a;
    --bg-felt-deep: #0f241a;
    --border-metal: #5c4326;
    --border-gold: #c8963e;
    --gold-bright: #ffd700;
    --bronze: #8b6b3e;
    --text-ivory: #f0e5da;
    --text-gold: #e4d5a0;
    --text-muted: #a89f91;
    --red-suit: #ff473a;
    --black-suit: #f5ede6;

    --basic-border: #8a765d;
    --trick-border: #2e6b52;
    --delayed-border: #6a3d7a;
    --equip-border: #8c622b;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    background: radial-gradient(circle at 50% 20%, #1e1711 0%, #0c0907 100%);
    color: var(--text-ivory);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Noto Serif", serif;
    padding: 24px 16px;
    min-height: 100vh;
  }

  .header {
    text-align: center;
    margin-bottom: 28px;
  }
  .header .badge {
    display: inline-block;
    padding: 4px 14px;
    background: rgba(200, 150, 62, 0.15);
    border: 1px solid var(--border-gold);
    color: var(--text-gold);
    font-size: 13px;
    letter-spacing: 2px;
    text-transform: uppercase;
    border-radius: 4px;
    margin-bottom: 10px;
  }
  .header h1 {
    font-size: 30px;
    color: #f7eed8;
    text-shadow: 0 2px 8px rgba(0,0,0,0.8), 0 0 20px rgba(200,150,62,0.4);
    margin-bottom: 8px;
  }
  .header p {
    color: var(--text-muted);
    font-size: 14.5px;
    max-width: 820px;
    margin: 0 auto;
    line-height: 1.5;
  }

  /* Control Panel Toolbar */
  .toolbar-panel {
    max-width: 1100px;
    margin: 0 auto 24px auto;
    background: rgba(26, 20, 14, 0.95);
    border: 2px solid var(--border-gold);
    border-radius: 8px;
    padding: 14px 20px;
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 14px;
    box-shadow: 0 8px 24px rgba(0,0,0,0.7);
  }
  .toolbar-group {
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .toolbar-label {
    font-size: 13px;
    font-weight: 700;
    color: var(--text-gold);
    text-transform: uppercase;
    letter-spacing: 1px;
  }
  .btn-pill {
    background: linear-gradient(180deg, #3d2b18 0%, #1c140c 100%);
    border: 1px solid var(--border-metal);
    color: var(--text-ivory);
    padding: 6px 14px;
    border-radius: 20px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    transition: all 0.2s ease;
  }
  .btn-pill:hover {
    border-color: var(--gold-bright);
    color: var(--gold-bright);
    transform: translateY(-1px);
  }
  .btn-pill.active {
    background: linear-gradient(180deg, #a66e27 0%, #5a3811 100%);
    border-color: var(--gold-bright);
    color: #fff9e6;
    box-shadow: 0 0 10px rgba(255,215,0,0.5);
  }

  /* Card Layout Container */
  .section {
    max-width: 1100px;
    margin: 0 auto 36px auto;
    background: rgba(22, 17, 13, 0.9);
    border: 2px solid var(--border-metal);
    border-radius: 8px;
    padding: 24px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.8);
  }
  .section-title {
    font-size: 20px;
    color: var(--text-gold);
    border-bottom: 1px solid rgba(200, 150, 62, 0.25);
    padding-bottom: 10px;
    margin-bottom: 20px;
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .section-title::before {
    content: "◆";
    color: var(--border-gold);
    font-size: 14px;
  }

  /* Bàn chơi nỉ xanh */
  .felt-board {
    background: radial-gradient(ellipse at center, #1b3d2b 0%, #0d1e15 100%);
    border: 3px solid var(--border-metal);
    border-radius: 12px;
    padding: 40px 20px 30px 20px;
    position: relative;
    box-shadow: inset 0 0 50px rgba(0,0,0,0.85), 0 8px 24px rgba(0,0,0,0.6);
    display: flex;
    flex-direction: column;
    align-items: center;
    overflow: visible;
    min-height: 270px;
    justify-content: flex-end;
  }
  .felt-board-title {
    position: absolute;
    top: 14px;
    left: 20px;
    color: rgba(240, 229, 218, 0.45);
    font-size: 13px;
    font-weight: 700;
    letter-spacing: 1px;
    text-transform: uppercase;
  }

  /* Dynamic Hand Container (Thanh ngang 0 độ) */
  .dynamic-hand-container {
    display: flex;
    justify-content: center;
    align-items: flex-end;
    width: 100%;
    position: relative;
    padding-bottom: 10px;
    overflow: visible;
  }

  /* Card Item Structure (100% FreeKill 93x130 ratio) */
  .sg-card-wrapper {
    position: relative;
    transition: margin 0.22s cubic-bezier(0.2, 0.9, 0.3, 1), transform 0.22s cubic-bezier(0.2, 0.9, 0.3, 1), z-index 0.1s;
    transform-origin: 50% 100%;
  }

  .sg-card-button {
    position: relative;
    width: 104px;
    height: 148px;
    border-radius: 6px;
    border: 2px solid var(--basic-border);
    box-shadow: 0 6px 14px rgba(0,0,0,0.6), inset 0 0 0 1px rgba(255,255,255,0.08);
    display: flex !important;
    flex-direction: column !important;
    justify-content: space-between !important;
    align-items: stretch !important;
    padding: 4px !important;
    user-select: none;
    cursor: pointer;
    background: #1d1712;
    color: var(--text-ivory);
    font-family: inherit;
    transition: transform 0.22s cubic-bezier(0.2, 0.9, 0.3, 1), box-shadow 0.22s ease, border-color 0.22s ease;
    overflow: visible;
  }

  /* Inner Parchment & Background */
  .sg-card-button::before {
    content: "";
    position: absolute;
    inset: 2px;
    border-radius: 4px;
    background: radial-gradient(circle at 50% 40%, rgba(255,255,255,0.05) 0%, rgba(0,0,0,0.4) 100%),
                linear-gradient(180deg, #2c2118 0%, #17110c 100%);
    z-index: 0;
  }

  /* Native Art Layer */
  .sg-card-native-art {
    position: absolute;
    inset: 1px;
    width: calc(100% - 2px);
    height: calc(100% - 2px);
    object-fit: cover;
    object-position: center top;
    border-radius: 4px;
    z-index: 1;
    pointer-events: none;
  }

  /* Top Left: Rank + Suit vertical stack (26px identification safe zone) */
  .sg-card-top-left {
    position: absolute;
    top: 3px;
    left: 3px;
    z-index: 3;
    display: flex;
    flex-direction: column;
    align-items: center;
    line-height: 1;
    min-width: 22px;
    padding: 2px 3px;
    background: rgba(10, 8, 6, 0.88);
    border: 1px solid rgba(200, 150, 62, 0.6);
    border-radius: 3px;
    box-shadow: 0 2px 5px rgba(0,0,0,0.85);
  }
  .sg-card-rank {
    font-size: 15px;
    font-weight: 900;
    font-family: -apple-system, BlinkMacSystemFont, "Impact", sans-serif;
    color: #fff;
    letter-spacing: -0.5px;
  }
  .sg-card-suit {
    font-size: 13px;
    font-weight: 900;
    margin-top: 1px;
  }
  .suit-red { color: var(--red-suit) !important; text-shadow: 0 0 6px rgba(255,71,58,0.7); }
  .suit-black { color: var(--black-suit) !important; text-shadow: 0 0 6px rgba(255,255,255,0.4); }

  /* Top Right: Category Badge */
  .sg-card-type-badge {
    position: absolute;
    top: 3px;
    right: 3px;
    z-index: 3;
    font-size: 10px;
    font-weight: 800;
    padding: 2px 4px;
    border-radius: 2px;
    background: rgba(12, 10, 7, 0.85);
    border: 1px solid rgba(200, 150, 62, 0.5);
    color: var(--text-gold);
    letter-spacing: 0.5px;
  }

  /* Bottom Banner: Card Name */
  .sg-card-banner {
    position: absolute;
    bottom: 3px;
    left: 3px;
    right: 3px;
    z-index: 3;
    background: linear-gradient(180deg, rgba(20, 14, 9, 0.85) 0%, rgba(10, 7, 5, 0.96) 100%);
    border: 1px solid rgba(200, 150, 62, 0.45);
    border-radius: 2px;
    padding: 3px 2px;
    text-align: center;
    box-shadow: 0 -2px 6px rgba(0,0,0,0.6);
  }
  .sg-card-name {
    font-size: 11.5px;
    font-weight: 800;
    color: #fcebd2;
    text-shadow: 0 1px 3px rgba(0,0,0,0.95);
    white-space: nowrap;
    overflow: hidden;
    text-overflow: ellipsis;
    display: block;
  }

  /* Category Border Variants */
  .type-basic { border-color: var(--basic-border) !important; }
  .type-trick { border-color: var(--trick-border) !important; }
  .type-delayed { border-color: var(--delayed-border) !important; }
  .type-equip { border-color: var(--equip-border) !important; }

  /* Hover & Touch Interaction (Straight Vertical Lift) */
  .sg-card-wrapper:hover,
  .sg-card-wrapper:focus-within {
    z-index: 100 !important;
  }
  .sg-card-wrapper:hover .sg-card-button,
  .sg-card-wrapper:focus-within .sg-card-button {
    transform: translateY(-24px) scale(1.04) !important;
    border-color: var(--gold-bright) !important;
    box-shadow: 0 16px 28px rgba(0,0,0,0.9), 0 0 18px rgba(255, 215, 0, 0.7) !important;
  }

  /* Selected State */
  .sg-card-wrapper.selected {
    z-index: 200 !important;
  }
  .sg-card-wrapper.selected .sg-card-button {
    transform: translateY(-30px) scale(1.05) !important;
    border-color: #ffd700 !important;
    box-shadow: 0 20px 32px rgba(0,0,0,0.95), 0 0 22px #ffd700 !important;
    outline: 2px solid #ffd700;
  }

  /* Dark Veil Disabled Overlay (FreeKill Style) */
  .sg-card-button.disabled {
    cursor: not-allowed;
  }
  .sg-card-button.disabled::after {
    content: "";
    position: absolute;
    inset: 0;
    background: rgba(10, 8, 6, 0.62);
    border-radius: inherit;
    z-index: 10;
    pointer-events: none;
  }

  /* Tooltip Popover */
  .sg-card-popover-tooltip {
    position: absolute;
    bottom: calc(100% + 14px);
    left: 50%;
    transform: translateX(-50%);
    width: 170px;
    background: #140e09;
    border: 1px solid var(--border-gold);
    box-shadow: 0 8px 20px rgba(0,0,0,0.9);
    border-radius: 6px;
    padding: 8px 10px;
    z-index: 300;
    pointer-events: none;
    opacity: 0;
    visibility: hidden;
    transition: opacity 0.15s ease, visibility 0.15s ease;
  }
  .sg-card-wrapper:hover .sg-card-popover-tooltip {
    opacity: 1;
    visibility: visible;
  }
  .sg-tip-title {
    color: var(--gold-bright);
    font-size: 12px;
    font-weight: 700;
    display: block;
    margin-bottom: 2px;
  }
  .sg-tip-desc {
    color: var(--text-ivory);
    font-size: 11px;
    line-height: 1.35;
  }

  /* Action Bar Display */
  .action-bar-status {
    width: 100%;
    margin-top: 16px;
    background: rgba(14, 11, 8, 0.95);
    border: 1px solid var(--border-gold);
    border-radius: 6px;
    padding: 10px 16px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .action-bar-info strong {
    color: var(--gold-bright);
    font-size: 13.5px;
  }
  .action-bar-info p {
    color: var(--text-muted);
    font-size: 12px;
    margin-top: 2px;
  }

  /* ---------------- MOBILE CARD STYLES (Ratio 93x130, width 72px) ---------------- */
  .mobile-card-btn {
    width: 72px !important;
    height: 101px !important;
    padding: 2px !important;
    border-width: 1.5px !important;
    border-radius: 5px !important;
  }
  .mobile-card-btn .sg-card-top-left {
    min-width: 18px !important;
    padding: 1px 2px !important;
    top: 2px !important;
    left: 2px !important;
    border-radius: 2px !important;
  }
  .mobile-card-btn .sg-card-rank { font-size: 12.5px !important; }
  .mobile-card-btn .sg-card-suit { font-size: 10.5px !important; margin-top: 0 !important; }
  .mobile-card-btn .sg-card-type-badge { font-size: 8px !important; padding: 1px 3px !important; top: 2px !important; right: 2px !important; }
  .mobile-card-btn .sg-card-banner { bottom: 2px !important; left: 2px !important; right: 2px !important; padding: 2px 1px !important; }
  .mobile-card-btn .sg-card-name { font-size: 9px !important; }
  .mobile-card-btn .sg-card-popover-tooltip { display: none !important; }

  /* Mobile Simulator Containers */
  .mobile-matrix-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(360px, 1fr));
    gap: 24px;
    justify-items: center;
    margin-top: 16px;
  }
  .mobile-case-wrapper {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 10px;
    width: 100%;
    max-width: 380px;
  }
  .mobile-case-badge {
    font-size: 13px;
    font-weight: 700;
    color: var(--gold-bright);
    background: rgba(200, 150, 62, 0.2);
    border: 1px solid var(--border-gold);
    border-radius: 20px;
    padding: 4px 14px;
    letter-spacing: 0.5px;
  }
  .mobile-sim-shell {
    width: 360px;
    background: #000;
    border-radius: 26px;
    padding: 10px;
    box-shadow: 0 16px 36px rgba(0,0,0,0.9), 0 0 0 2px #3d2d1c;
  }
  .mobile-screen {
    background: radial-gradient(circle at 50% 30%, #172a20 0%, #09130d 100%);
    border-radius: 18px;
    overflow: hidden;
    height: 460px;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
    padding: 12px;
    position: relative;
  }
  .mobile-header-bar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid rgba(200,150,62,0.3);
    padding-bottom: 6px;
  }
  .mobile-center-area {
    text-align: center;
    color: rgba(240, 229, 218, 0.35);
    font-size: 11.5px;
    margin: auto;
  }
  .mobile-action-bar {
    background: rgba(14, 11, 8, 0.96);
    border: 1px solid var(--border-gold);
    border-radius: 6px;
    padding: 6px 10px;
    margin-bottom: 6px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
  }
  .mobile-action-bar strong {
    color: var(--gold-bright);
    font-size: 11.5px;
  }
  .mobile-action-bar p {
    color: var(--text-muted);
    font-size: 10px;
    margin-top: 1px;
  }
  .mobile-stats-row {
    color: var(--text-gold);
    font-size: 11.5px;
    text-align: center;
    margin-top: 4px;
    font-family: monospace;
  }
</style>
</head>
<body>

  <div class="header">
    <div class="badge">Kiểm chứng Nghiệm thu Mỹ thuật</div>
    <h1>Nâng Cấp Vùng Tay Bài: Thanh Ngang Thẳng Đứng 0° &amp; Gối Lớp Tự Động</h1>
    <p>Tuân thủ tuyệt đối quy chuẩn nguyên bản của <strong>FreeKill</strong> (<code>ItemArea.qml</code>), <strong>QSanguosha</strong> (<code>dashboard.cpp</code>) và <strong>Sanguosha Mobile</strong>: các lá bài luôn thẳng đứng 0° trên một đường ngang cơ sở, tự động co gối lớp khi nhiều bài để lộ dải 26px Chất &amp; Điểm, nhấc thẳng khi hover/chọn mà không xoay vẹo.</p>
  </div>

  <!-- CONTROL TOOLBAR -->
  <div class="toolbar-panel">
    <div class="toolbar-group">
      <span class="toolbar-label">Thử nghiệm số lượng:</span>
      <button type="button" class="btn-pill" onclick="setCount(3)">3 Lá (Đứng thoáng)</button>
      <button type="button" class="btn-pill" onclick="setCount(5)">5 Lá (Chuẩn)</button>
      <button type="button" class="btn-pill active" onclick="setCount(8)">8 Lá (Gối lớp)</button>
      <button type="button" class="btn-pill" onclick="setCount(10)">10 Lá (Cực đại)</button>
    </div>
    <div class="toolbar-group">
      <span class="toolbar-label">Tính năng:</span>
      <button type="button" class="btn-pill" id="toggle-disabled-btn" onclick="toggleDisabled()">Thử Nghiệm Màn Tối (Dark Veil)</button>
    </div>
  </div>

  <!-- SECTION 1: INTERACTIVE DESKTOP FELT BOARD -->
  <section class="section">
    <div class="section-title">1. Bàn Chơi Thực Chiến Desktop (Thanh Ngang Thẳng Đứng 0° &amp; Gối Lớp Tự Động)</div>
    <div class="felt-board">
      <span class="felt-board-title">Bàn Chơi Quốc Chiến · Thanh Điều Khiển Tay Bài (Dashboard Dock)</span>

      <!-- Interactive Hand Fan Container -->
      <div class="dynamic-hand-container" id="hand-cards-root">
        <!-- Rendered dynamically by JS -->
      </div>

      <div class="action-bar-status">
        <div class="action-bar-info">
          <strong id="selected-card-label">Chưa chọn lá bài nào</strong>
          <p id="selected-card-desc">Di chuột (hover) để nhấc bài và xem thông tin; nhấp chuột để chọn bài.</p>
        </div>
        <div>
          <button type="button" class="btn-pill active" style="font-size: 13px; padding: 6px 18px;" id="confirm-card-btn" disabled>Xác Nhận Đánh</button>
        </div>
      </div>
    </div>
  </section>

  <!-- SECTION 2: 4-CASE MOBILE MATRIX (3, 5, 8, 10 CARDS) -->
  <section class="section">
    <div class="section-title">2. Đối Chiếu Toàn Diện 4 Trạng Thái Số Lượng Bài Trên Mobile (Khung Hình 390px)</div>
    <p style="color: var(--text-muted); font-size: 13.5px; margin-bottom: 20px;">
      Kiểm chứng kích thước 72 × 101 px (chuẩn tỉ lệ gốc 93:130) trên chiều rộng màn hình điện thoại 360px: dù người chơi cầm 3, 5, 8 hay 10 lá bài, toàn bộ lá bài đều nằm trọn vẹn trong màn hình, dải lề nhận diện 26px bên trái luôn luôn lộ diện 100% mà không bao giờ bị che khuất hay bắt người chơi phải cuộn ngang.
    </p>

    <div class="mobile-matrix-grid">

      <!-- CASE A: 3 CARDS -->
      <div class="mobile-case-wrapper">
        <div class="mobile-case-badge">Trường hợp 1: 3 Lá (Đứng thoáng)</div>
        <div class="mobile-sim-shell">
          <div class="mobile-screen">
            <div class="mobile-header-bar">
              <span style="font-size: 12px; color: var(--text-gold); font-weight: bold;">Quốc Chiến Mobile</span>
              <span style="font-size: 11px; color: #a89f91;">♥ 4 / 4 | 3 Thẻ bài</span>
            </div>
            <div class="mobile-center-area">Khu vực bàn chơi &amp; tướng</div>
            <div style="width: 100%;">
              <div class="mobile-action-bar">
                <div>
                  <strong>【Vô Trung Sinh Hữu】 (♥ 7)</strong>
                  <p>Rút ngay 2 lá bài từ chồng bài rút.</p>
                </div>
                <button type="button" class="btn-pill active" style="font-size: 10px; padding: 3px 8px;">Đánh</button>
              </div>
              <div class="dynamic-hand-container" id="mobile-case-3"></div>
              <div class="mobile-stats-row">Khoảng cách: gap 8px | Độ hở: 72px (100%)</div>
            </div>
          </div>
        </div>
      </div>

      <!-- CASE B: 5 CARDS -->
      <div class="mobile-case-wrapper">
        <div class="mobile-case-badge">Trường hợp 2: 5 Lá (Chuẩn trận)</div>
        <div class="mobile-sim-shell">
          <div class="mobile-screen">
            <div class="mobile-header-bar">
              <span style="font-size: 12px; color: var(--text-gold); font-weight: bold;">Quốc Chiến Mobile</span>
              <span style="font-size: 11px; color: #a89f91;">♥ 4 / 4 | 5 Thẻ bài</span>
            </div>
            <div class="mobile-center-area">Khu vực bàn chơi &amp; tướng</div>
            <div style="width: 100%;">
              <div class="mobile-action-bar">
                <div>
                  <strong>【Nỏ Liên Châu】 (♦ A)</strong>
                  <p>Trong lượt ra bài, có thể ra vô hạn Sát.</p>
                </div>
                <button type="button" class="btn-pill active" style="font-size: 10px; padding: 3px 8px;">Đánh</button>
              </div>
              <div class="dynamic-hand-container" id="mobile-case-5"></div>
              <div class="mobile-stats-row">Gối lớp: -14px | Độ hở: 58px (&gt;26px)</div>
            </div>
          </div>
        </div>
      </div>

      <!-- CASE C: 8 CARDS -->
      <div class="mobile-case-wrapper">
        <div class="mobile-case-badge">Trường hợp 3: 8 Lá (Gối lớp dày)</div>
        <div class="mobile-sim-shell">
          <div class="mobile-screen">
            <div class="mobile-header-bar">
              <span style="font-size: 12px; color: var(--text-gold); font-weight: bold;">Quốc Chiến Mobile</span>
              <span style="font-size: 11px; color: #a89f91;">♥ 3 / 4 | 8 Thẻ bài</span>
            </div>
            <div class="mobile-center-area">Khu vực bàn chơi &amp; tướng</div>
            <div style="width: 100%;">
              <div class="mobile-action-bar">
                <div>
                  <strong>【Thích Sát】 (♦ 9)</strong>
                  <p>Mục tiêu cần 2 lá Thiểm mới hóa giải được.</p>
                </div>
                <button type="button" class="btn-pill active" style="font-size: 10px; padding: 3px 8px;">Đánh</button>
              </div>
              <div class="dynamic-hand-container" id="mobile-case-8"></div>
              <div class="mobile-stats-row">Gối lớp: -32px | Độ hở: 40px (&gt;26px)</div>
            </div>
          </div>
        </div>
      </div>

      <!-- CASE D: 10 CARDS -->
      <div class="mobile-case-wrapper">
        <div class="mobile-case-badge">Trường hợp 4: 10 Lá (Cực đại không cuộn)</div>
        <div class="mobile-sim-shell">
          <div class="mobile-screen">
            <div class="mobile-header-bar">
              <span style="font-size: 12px; color: var(--text-gold); font-weight: bold;">Quốc Chiến Mobile</span>
              <span style="font-size: 11px; color: #a89f91;">♥ 4 / 4 | 10 Thẻ bài</span>
            </div>
            <div class="mobile-center-area">Khu vực bàn chơi &amp; tướng</div>
            <div style="width: 100%;">
              <div class="mobile-action-bar">
                <div>
                  <strong>【Quá Hà Sách Kiều】 (♠ 3)</strong>
                  <p>Hủy 1 lá bài bất kỳ của đối thủ.</p>
                </div>
                <button type="button" class="btn-pill active" style="font-size: 10px; padding: 3px 8px;">Đánh</button>
              </div>
              <div class="dynamic-hand-container" id="mobile-case-10"></div>
              <div class="mobile-stats-row">Gối lớp: -41px | Độ hở: 31px (&gt;26px an toàn)</div>
            </div>
          </div>
        </div>
      </div>

    </div>
  </section>

<script>
  const ALL_CARDS = ${cardsJson};
  let currentCount = 8;
  let testDisabled = false;
  let selectedId = "ex_crossbow";

  // Desktop calculation (Width 104px)
  function getDesktopStyle(index, total) {
    const overlap = total > 4 ? Math.min(42, 16 + (total - 4) * 4.5) : 0;
    return {
      marginLeft: index === 0 ? "0px" : "-" + overlap + "px",
      zIndex: index + 1
    };
  }

  // Mobile calculation (Width 72px, available width ~ 336px)
  function getMobileStyle(index, total) {
    if (total <= 3) {
      return { marginLeft: index === 0 ? "0px" : "8px", zIndex: index + 1 };
    }
    const cardW = 72;
    const availW = 336;
    const xLimit = availW - cardW;
    const spacing = Math.min(cardW, xLimit / (total - 1));
    const overlap = Math.max(0, cardW - spacing);
    return {
      marginLeft: index === 0 ? "0px" : "-" + Math.round(overlap) + "px",
      zIndex: index + 1
    };
  }

  function createCardHtml(c, isMobile, isSelected, isDisabled) {
    const btnClass = isMobile ? "sg-card-button mobile-card-btn" : "sg-card-button";
    return \`
      <button type="button" class="\${btnClass} \${c.type} \${isDisabled ? "disabled" : ""}"
              onclick="selectCard('\${c.id}')">
        <img class="sg-card-native-art" src="\${c.b64}" alt="" aria-hidden="true">
        <div class="sg-card-top-left">
          <span class="sg-card-rank">\${c.rank}</span>
          <span class="sg-card-suit \${c.color}">\${c.suit}</span>
        </div>
        <span class="sg-card-type-badge">\${c.cat}</span>
        <div class="sg-card-banner">
          <span class="sg-card-name">\${c.name}</span>
        </div>
        <span class="sg-card-popover-tooltip">
          <strong class="sg-tip-title">\${c.name} (\${c.suit} \${c.rank})</strong>
          <span class="sg-tip-desc">\${c.desc}</span>
        </span>
      </button>
    \`;
  }

  function renderDesktop() {
    const root = document.getElementById("hand-cards-root");
    root.innerHTML = "";
    const activeCards = ALL_CARDS.slice(0, currentCount);

    activeCards.forEach((c, idx) => {
      const style = getDesktopStyle(idx, activeCards.length);
      const isSelected = (c.id === selectedId);
      const isDisabled = testDisabled && (idx % 3 === 2);

      const wrapper = document.createElement("div");
      wrapper.className = "sg-card-wrapper " + (isSelected ? "selected" : "");
      wrapper.style.marginLeft = style.marginLeft;
      wrapper.style.zIndex = isSelected ? 200 : style.zIndex;
      wrapper.innerHTML = createCardHtml(c, false, isSelected, isDisabled);
      root.appendChild(wrapper);
    });

    updateStatusBar();
  }

  function renderMobileCase(targetId, count, selectedTargetId) {
    const container = document.getElementById(targetId);
    if (!container) return;
    container.innerHTML = "";
    const activeCards = ALL_CARDS.slice(0, count);

    activeCards.forEach((c, idx) => {
      const style = getMobileStyle(idx, activeCards.length);
      const isSelected = (c.id === selectedTargetId);
      const isDisabled = testDisabled && (idx % 4 === 1);

      const wrapper = document.createElement("div");
      wrapper.className = "sg-card-wrapper " + (isSelected ? "selected" : "");
      wrapper.style.marginLeft = style.marginLeft;
      wrapper.style.zIndex = isSelected ? 200 : style.zIndex;
      wrapper.innerHTML = createCardHtml(c, true, isSelected, isDisabled);
      container.appendChild(wrapper);
    });
  }

  function renderAll() {
    renderDesktop();
    renderMobileCase("mobile-case-3", 3, "v33__ex_nihilo");
    renderMobileCase("mobile-case-5", 5, "ex_crossbow");
    renderMobileCase("mobile-case-8", 8, "stab__slash");
    renderMobileCase("mobile-case-10", 10, "v11__dismantlement");
  }

  function selectCard(id) {
    selectedId = (selectedId === id) ? null : id;
    renderAll();
  }

  function setCount(n) {
    currentCount = n;
    document.querySelectorAll(".toolbar-group .btn-pill").forEach(btn => {
      if (btn.innerText.includes(n + " Lá")) btn.classList.add("active");
      else if (btn.innerText.includes("Lá")) btn.classList.remove("active");
    });
    renderAll();
  }

  function toggleDisabled() {
    testDisabled = !testDisabled;
    document.getElementById("toggle-disabled-btn").classList.toggle("active", testDisabled);
    renderAll();
  }

  function updateStatusBar() {
    const label = document.getElementById("selected-card-label");
    const desc = document.getElementById("selected-card-desc");
    const confirmBtn = document.getElementById("confirm-card-btn");

    if (!selectedId) {
      label.innerText = "Chưa chọn lá bài nào";
      desc.innerText = "Di chuột (hover) để nhấc bài và xem thông tin; nhấp chuột để chọn bài.";
      confirmBtn.disabled = true;
      confirmBtn.style.opacity = "0.5";
    } else {
      const card = ALL_CARDS.find(c => c.id === selectedId);
      if (card) {
        label.innerText = "Đang chọn: 【" + card.name + "】 (" + card.suit + " " + card.rank + ") - [" + card.cat + "]";
        desc.innerText = card.desc;
        confirmBtn.disabled = false;
        confirmBtn.style.opacity = "1";
      }
    }
  }

  // Initial render
  renderAll();
</script>
</body>
</html>`;

fs.writeFileSync(path.join(repo, "game/web/public/handcard-mockup.html"), html);
const artifactPath = "/Users/otada/.gemini/antigravity/brain/c9930c20-0ab8-4476-8dbb-395b52928420/sanguosha_handcard_mockup.html";
fs.writeFileSync(artifactPath, html);
console.log("Written updated handcard-mockup.html successfully to public & artifact dir!");
