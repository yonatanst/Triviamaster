// lib/types.ts
export type Category = "geography" | "history" | "sports" | "movies" | "general";

export interface Question {
  id: string;               // canonical (sha1) we compute server-side
  category: Category;
  locale: "en" | "he";
  difficulty: "easy" | "medium" | "hard";
  question: string;
  choices: string[];
  answer: string;           // must be one of choices
  meta?: Record<string, any>;
}

export interface GenRequest {
  uid: string;
  rating?: number;                // 800-2000-ish
  categories?: Category[];
  seen?: string[];                // client-side seen ids (we also persist)
  locale?: "en" | "he";
}

export interface GenBatchRequest extends GenRequest {
  count: number;                  // total number to return
  perCategory?: number;           // optional, else split evenly
}
