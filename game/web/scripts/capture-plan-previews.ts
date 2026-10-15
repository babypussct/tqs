import { chromium } from 'playwright-core';
import path from 'path';

const outDir = '/Users/otada/.gemini/antigravity/brain/c9930c20-0ab8-4476-8dbb-395b52928420';
const baseUrl = process.env.TQS_CAPTURE_BASE_URL ?? 'http://127.0.0.1:5174';

async function capture() {
  const browser = await chromium.launch({
    executablePath: '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    headless: true,
  });

  const page = await browser.newPage({
    viewport: { width: 1200, height: 1600 },
    deviceScaleFactor: 2,
  });

  console.log(`Navigating to ${baseUrl}/plan-previews.html...`);
  await page.goto(`${baseUrl}/plan-previews.html`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(1000);

  // Capture Card 1: Self Photo Anatomy
  const card1 = page.locator('#cardStep1');
  if (await card1.count() > 0) {
    await card1.screenshot({ path: path.join(outDir, 'plan_step1_self_photo_preview.png') });
    console.log('Saved plan_step1_self_photo_preview.png');
  }

  // Capture Card 2: Handcards & Flat Skills
  const card2 = page.locator('#cardStep2');
  if (await card2.count() > 0) {
    await card2.screenshot({ path: path.join(outDir, 'plan_step2_handcards_and_skills_preview.png') });
    console.log('Saved plan_step2_handcards_and_skills_preview.png');
  }

  // Capture Card 3: Floating Controls HUD
  const card3 = page.locator('#cardStep3');
  if (await card3.count() > 0) {
    await card3.screenshot({ path: path.join(outDir, 'plan_step3_floating_controls_preview.png') });
    console.log('Saved plan_step3_floating_controls_preview.png');
  }

  // Capture Card 4: Unified Bottom Dashboard
  const card4 = page.locator('#cardStep4');
  if (await card4.count() > 0) {
    await card4.screenshot({ path: path.join(outDir, 'plan_step4_unified_dashboard_preview.png') });
    console.log('Saved plan_step4_unified_dashboard_preview.png');
  }

  // Capture Card 5: Full Table Layout & Right-Side Log
  const card5 = page.locator('#cardStep5');
  if (await card5.count() > 0) {
    await card5.screenshot({ path: path.join(outDir, 'plan_step5_table_and_right_log_preview.png') });
    console.log('Saved plan_step5_table_and_right_log_preview.png');
  }

  // Capture Full Page
  await page.screenshot({ path: path.join(outDir, 'plan_all_previews_fullpage.png'), fullPage: true });
  console.log('Saved plan_all_previews_fullpage.png');

  await browser.close();
  console.log('Done capturing all plan previews!');
}

capture().catch((err) => {
  console.error('Error during capture:', err);
  process.exit(1);
});
