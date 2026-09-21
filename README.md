<div align="center">
<img width="1200" height="475" alt="GHBanner" src="https://github.com/user-attachments/assets/0aa67016-6eaf-458a-adb2-6e31a0763ed6" />
</div>

# Run and deploy your AI Studio app

This contains everything you need to run your app locally.

View your app in AI Studio: https://ai.studio/apps/ae9f678c-29b1-4f19-b872-e5b15e1cee0b

## Run Locally

**Prerequisites:** Node.js 20+

1. Install dependencies:
   ```bash
   npm ci
   ```
2. Setup environment variables (optional for basic local dev):
   ```bash
   cp .env.example .env.local
   ```
3. Run the development server:
   ```bash
   npm run dev
   ```
4. Check types & build:
   ```bash
   npm run lint
   npm run build
   ```
