// Drop this entire file into: functions/src/index.ts
// Fixes TypeScript JSON typing for the OpenAI response and supports .env on Spark plan.

import 'dotenv/config'; // loads LLM_API_KEY from functions/.env if present
import * as functions from 'firebase-functions/v2';
import * as logger from 'firebase-functions/logger';
import * as admin from 'firebase-admin';
import crypto from 'crypto';

admin.initializeApp();
const db = admin.firestore();

function difficultyFromRating(rating: number): number {
  const d = Math.floor((rating - 800) / 200) + 1; // ~ every 200 rating
  return Math.max(1, Math.min(5, d));
}

async function callLLM({
  locale,
  categories,
  difficulty,
  apiKey,
}: {
  locale: string;
  categories: string[];
  difficulty: number;
  apiKey: string;
}) {
  const prompt = `
Create exactly ONE multiple-choice trivia question in ${locale}.
Respond ONLY with strict JSON (no markdown) with fields:
{
  "text": string,
  "options": [string, string, string, string],
  "answerIndex": 0|1|2|3,
  "category": string,
  "difficulty": 1|2|3|4|5
}
Constraints:
- Facts must be accurate and unambiguous.
- Options must be plausible and mutually exclusive.
- Difficulty=${difficulty}.
- Category preference: ${categories.join(', ') || 'general'}.
`.trim();

  const body = {
    model: 'gpt-4o-mini', // any JSON-capable model you have access to
    messages: [{ role: 'user', content: prompt }],
    response_format: { type: 'json_object' },
    temperature: 0.4,
  };

  const r = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(body),
  });

  if (!r.ok) {
    const text = await r.text();
    throw new Error(`LLM error ${r.status}: ${text}`);
  }

  const data: any = await r.json(); // <-- explicitly any to silence TS complaints
  const content = data?.choices?.[0]?.message?.content ?? data?.choices?.[0]?.text ?? null;
  if (!content || typeof content !== 'string') {
    throw new Error('Unexpected LLM response format; no content string found.');
  }

  let parsed: any;
  try {
    parsed = JSON.parse(content);
  } catch (e) {
    throw new Error('LLM returned non-JSON content');
  }

  if (!parsed?.text || !Array.isArray(parsed.options) || parsed.options.length !== 4 || typeof parsed.answerIndex !== 'number') {
    throw new Error('Malformed question JSON from LLM');
  }

  parsed.category = parsed.category || (categories[0] ?? 'general');
  parsed.difficulty = parsed.difficulty ?? difficulty;
  return parsed;
}

export const genQuestion = functions.https.onCall(
  { region: 'us-central1', cors: true, memory: '256MiB', timeoutSeconds: 15 },
  async (request) => {
    try {
      const authUid = request.auth?.uid;
      const { uid, rating = 1200, categories = ['general'], locale = 'en' } = (request.data as any) || {};

      if (!authUid) {
        throw new functions.https.HttpsError('unauthenticated', 'User must be signed in.');
      }
      if (!uid || uid !== authUid) {
        throw new functions.https.HttpsError('permission-denied', 'UID mismatch or missing.');
      }

      const apiKey = process.env.LLM_API_KEY || process.env.OPENAI_API_KEY;
      if (!apiKey) {
        throw new functions.https.HttpsError('failed-precondition', 'Missing LLM_API_KEY / OPENAI_API_KEY.');
      }

      const diff = difficultyFromRating(Number(rating) || 1200);
      const parsed = await callLLM({ locale, categories, difficulty: diff, apiKey });

      const qhash = crypto.createHash('sha256').update(`${parsed.text}||${parsed.options.join('|')}`).digest('hex');

      const seenRef = db.doc(`/user_seen/${uid}/seen/${qhash}`);
      const seenSnap = await seenRef.get();
      if (seenSnap.exists) {
        throw new functions.https.HttpsError('already-exists', 'Question already seen by user.');
      }

      const qRef = db.collection('questions').doc(qhash);
      const qSnap = await qRef.get();
      if (!qSnap.exists) {
        await qRef.set({
          text: parsed.text,
          options: parsed.options,
          answerIndex: parsed.answerIndex,
          category: parsed.category,
          difficulty: parsed.difficulty,
          source: 'ai:v1',
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          hash: qhash,
        });
      }

      await seenRef.set({ qhash, at: admin.firestore.FieldValue.serverTimestamp() });
      logger.info('Generated question', { uid, qhash, category: parsed.category, difficulty: parsed.difficulty });

      return { ...parsed, hash: qhash };
    } catch (err: any) {
      logger.error('genQuestion failed', { error: err?.message });
      if (err instanceof functions.https.HttpsError) throw err;
      throw new functions.https.HttpsError('internal', err?.message ?? 'error');
    }
  }
);
