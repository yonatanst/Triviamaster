\# TriviaMaster API (Vercel)



Minimal serverless API to generate MCQ trivia questions with OpenAI, no Firebase billing required.



\## 1) Create project

\- Make a folder: `C:\\\\triviamaster-api`

\- Create subfolder `api`.

\- Add files: `package.json`, `api/genQuestion.js` (from this doc).



\## 2) Deploy to Vercel

\- Create a free account at https://vercel.com (if you don’t have one)

\- New Project → \*\*Import\*\* → Framework Preset: \*\*Other\*\*

\- Upload the two files (or connect a Git repo with them)

\- In \*\*Project Settings → Environment Variables\*\*, add:

&nbsp; - `OPENAI\_API\_KEY` = your OpenAI API key

\- Deploy → you’ll get a domain like `https://triviamaster-api-xxxx.vercel.app`

\- Your endpoint: `https://triviamaster-api-xxxx.vercel.app/api/genQuestion`



\## 3) Patch Flutter app

In your Flutter app, add dependency:



