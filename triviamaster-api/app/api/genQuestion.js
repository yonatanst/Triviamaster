// Minimal, dependency-free Vercel Serverless Function (Node.js runtime)

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
  res.setHeader('Vary', 'Origin');
}

function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }
function shuffle(arr) { return arr.slice().sort(() => Math.random() - 0.5); }

function generateQuestion(category) {
  // tiny bank to prove end-to-end; you can expand freely
  const bank = {
    geography: [
      ['What is the capital of France?', 'Paris', ['Rome', 'Berlin', 'Madrid']],
      ['Which desert is the largest hot desert?', 'Sahara', ['Gobi', 'Kalahari', 'Atacama']],
      ['Which river flows through Baghdad?', 'Tigris', ['Euphrates', 'Nile', 'Jordan']],
    ],
    history: [
      ['Who was the first President of the United States?', 'George Washington', ['John Adams','Thomas Jefferson','James Madison']],
      ['In what year did World War II end?', '1945', ['1939','1942','1948']],
    ],
    science: [
      ['H2O is the chemical formula for what?', 'Water', ['Oxygen','Hydrogen','Salt']],
      ['What planet is known as the Red Planet?', 'Mars', ['Venus','Jupiter','Mercury']],
    ],
    general: [
      ['How many continents are there?', '7', ['5','6','8']],
      ['What is the tallest animal?', 'Giraffe', ['Elephant','Horse','Ostrich']],
    ],
  };

  const pool = bank[category] || bank.general;
  const [text, correct, wrong] = pick(pool);
  const options = shuffle([correct, ...wrong]);
  return { text, options, answerIndex: options.indexOf(correct) };
}

export default async function handler(req, res) {
  try {
    cors(res);

    if (req.method === 'OPTIONS') {
      res.status(200).end();
      return;
    }
    if (req.method !== 'POST') {
      res.status(405).json({ error: 'Only POST is allowed' });
      return;
    }

    // Robust body parsing (handles text/plain and JSON)
    let body = req.body;
    if (!body || (typeof body === 'string')) {
      const raw = typeof body === 'string' ? body : await new Promise((resolve, reject) => {
        let data = '';
        req.on('data', (c) => (data += c));
        req.on('end', () => resolve(data));
        req.on('error', reject);
      });
      try { body = raw ? JSON.parse(raw) : {}; } catch { body = {}; }
    }

    const {
      uid = 'anon',
      rating = 1200,
      categories = [],
      seen = [],
      locale = 'en',
    } = (body || {});

    const category = (Array.isArray(categories) && categories[0]) ? String(categories[0]) : 'general';

    const q = generateQuestion(category);
    // If you send a 'seen' array of question texts, avoid repeats:
    if (Array.isArray(seen) && seen.includes(q.text)) {
      const alt = generateQuestion(category);
      if (!seen.includes(alt.text)) {
        res.status(200).json({ ...alt, category, difficulty: rating, locale, uid });
        return;
      }
    }

    res.status(200).json({ ...q, category, difficulty: rating, locale, uid });
  } catch (e) {
    res.status(500).json({ error: String(e && e.message ? e.message : e) });
  }
}
