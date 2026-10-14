import { chromium } from 'playwright-core';
import path from 'path';

const outDir = '/Users/otada/.gemini/antigravity/brain/c9930c20-0ab8-4476-8dbb-395b52928420';
const baseUrl = process.env.TQS_CAPTURE_BASE_URL ?? 'http://127.0.0.1:5174';

async function verifyAndCapture() {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
  });

  const page = await browser.newPage({
    viewport: { width: 1440, height: 1100 },
    deviceScaleFactor: 2,
  });

  console.log(`Navigating to ${baseUrl}/interactive-board-comparison.html...`);
  await page.goto(`${baseUrl}/interactive-board-comparison.html`, { waitUntil: 'networkidle' });

  // Function to inspect seat bounding boxes and verify NO collision
  async function checkCollisions(modeLabel: string) {
    const seats = await page.$$('.native-photo-seat');
    console.log(`\n--- Verification for ${modeLabel}: Found ${seats.length} opponent seats ---`);
    const boxes = [];
    for (let i = 0; i < seats.length; i++) {
      const box = await seats[i].boundingBox();
      const id = await seats[i].getAttribute('id');
      if (box) {
        boxes.push({ id, ...box });
        console.log(`  ${id}: x=${box.x.toFixed(1)}, y=${box.y.toFixed(1)}, w=${box.width.toFixed(1)}, h=${box.height.toFixed(1)}`);
      }
    }

    // Check pairwise overlap
    let collisions = 0;
    for (let i = 0; i < boxes.length; i++) {
      for (let j = i + 1; j < boxes.length; j++) {
        const b1 = boxes[i];
        const b2 = boxes[j];
        const overlapX = Math.max(0, Math.min(b1.x + b1.width, b2.x + b2.width) - Math.max(b1.x, b2.x));
        const overlapY = Math.max(0, Math.min(b1.y + b1.height, b2.y + b2.height) - Math.max(b1.y, b2.y));
        if (overlapX > 0 && overlapY > 0) {
          console.error(`  ⚠️ COLLISION between ${b1.id} and ${b2.id}! Overlap: ${overlapX.toFixed(1)}px x ${overlapY.toFixed(1)}px`);
          collisions++;
        }
      }
    }
    if (collisions === 0) {
      console.log(`  ✅ 100% PASS: ZERO OVERLAP between any opponent seats in ${modeLabel}!`);
    } else {
      throw new Error(`Found ${collisions} seat collisions in ${modeLabel}`);
    }
  }

  // 1. 8 Seats Desktop
  console.log('\n[1] Capturing 8 Seats Desktop...');
  await page.click('#btnCount8');
  await page.click('#btnDevDesktop');
  await page.waitForTimeout(400);
  await checkCollisions('8 Seats Desktop');
  const tableEl = await page.$('.native-felt-table');
  if (tableEl) {
    await tableEl.screenshot({ path: path.join(outDir, 'mockup_native_8p_ellipse_desktop.png') });
  }
  // 1b. Capture Targeting Mode (Crosshair, Beam, Drunk state)
  await page.click('#toggleTarget');
  await page.click('#toggleDrunk');
  await page.waitForTimeout(300);
  if (tableEl) {
    await tableEl.screenshot({ path: path.join(outDir, 'mockup_native_8p_ellipse_targeting.png') });
  }
  await page.click('#toggleTarget');
  await page.click('#toggleDrunk');
  await page.waitForTimeout(200);

  // 2. 10 Seats Desktop
  console.log('\n[2] Capturing 10 Seats Desktop...');
  await page.click('#btnCount10');
  await page.waitForTimeout(400);
  await checkCollisions('10 Seats Desktop');
  if (tableEl) {
    await tableEl.screenshot({ path: path.join(outDir, 'mockup_native_10p_ellipse_desktop.png') });
  }
  await page.screenshot({ path: path.join(outDir, 'mockup_native_10p_ellipse_split.png'), fullPage: false });

  // 3. 8 Seats Mobile 390px
  console.log('\n[3] Capturing 8 Seats Mobile 390px...');
  await page.click('#btnDev390');
  await page.click('#btnCount8');
  await page.waitForTimeout(400);
  await checkCollisions('8 Seats Mobile 390px');
  const phoneEl = await page.$('#frameProposal');
  if (phoneEl) {
    await phoneEl.screenshot({ path: path.join(outDir, 'mockup_native_8p_ellipse_mobile.png') });
  }

  // 4. 10 Seats Mobile 390px
  console.log('\n[4] Capturing 10 Seats Mobile 390px...');
  await page.click('#btnCount10');
  await page.waitForTimeout(400);
  await checkCollisions('10 Seats Mobile 390px');
  if (phoneEl) {
    await phoneEl.screenshot({ path: path.join(outDir, 'mockup_native_10p_ellipse_mobile.png') });
  }

  // 5. Capture Single Seat Anatomy Deep-Dive (2.5x Zoom)
  console.log('\n[5] Capturing Single Seat Anatomy Deep-Dive Section...');
  await page.click('#btnDevDesktop');
  await page.waitForTimeout(400);
  const anatomyEl = await page.$('#anatomySection');
  if (anatomyEl) {
    await anatomyEl.scrollIntoViewIfNeeded();
    await page.waitForTimeout(300);
    await anatomyEl.screenshot({ path: path.join(outDir, 'mockup_native_single_seat_zoom.png') });
    console.log('  ✅ Captured mockup_native_single_seat_zoom.png!');
  }

  // 6. Capture Zoomed-In Individual Seat on Board (Seat 2 - Tào Tháo)
  const seat2El = await page.$('#nativeSeat2');
  if (seat2El) {
    await seat2El.scrollIntoViewIfNeeded();
    await seat2El.screenshot({ path: path.join(outDir, 'mockup_native_seat2_on_board.png') });
    console.log('  ✅ Captured mockup_native_seat2_on_board.png!');
  }

  await browser.close();
  console.log('\nAll collision checks and screenshot captures finished!');
}

verifyAndCapture().catch(err => {
  console.error('Execution failed:', err);
  process.exit(1);
});
