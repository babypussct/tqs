import type { VercelRequest, VercelResponse } from '@vercel/node';
import { FieldValue } from 'firebase-admin/firestore';
import { getAdminDb } from './_lib/firebaseAdmin.js';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') return res.status(405).json({ success: false, code: 'METHOD_NOT_ALLOWED' });
  const postId = typeof req.body?.postId === 'string' ? req.body.postId.trim() : '';
  if (!postId || postId.includes('/') || postId.length > 150) {
    return res.status(400).json({ success: false, code: 'INVALID_POST_ID' });
  }

  try {
    const db = getAdminDb();
    const ref = db.collection('posts').doc(postId);
    const snapshot = await ref.get();
    if (!snapshot.exists || snapshot.data()?.status !== 'published') {
      return res.status(404).json({ success: false, code: 'POST_NOT_FOUND' });
    }
    await ref.update({ viewCount: FieldValue.increment(1) });
    return res.status(204).end();
  } catch (error) {
    console.error('Post view tracking failed:', error instanceof Error ? error.message : error);
    return res.status(204).end();
  }
}
