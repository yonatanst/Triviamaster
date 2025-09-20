// lib/storage.ts
// Pluggable storage: In-memory for dev, Upstash Redis for prod (Vercel-friendly)
type SeenKey = { uid: string; category: string };

export interface Storage {
  getSeen(key: SeenKey): Promise<Set<string>>;
  addSeen(key: SeenKey, ids: string[]): Promise<void>;
  // optional: cap set size to reduce unbounded growth
  trimSeen?(key: SeenKey, maxSize: number): Promise<void>;
}

class InMemoryStorage implements Storage {
  private store = new Map<string, Set<string>>();
  private key({ uid, category }: SeenKey) { return `seen:${uid}:${category}`; }
  async getSeen(key: SeenKey) {
    return new Set(this.store.get(this.key(key)) ?? []);
  }
  async addSeen(key: SeenKey, ids: string[]) {
    const k = this.key(key);
    const cur = this.store.get(k) ?? new Set<string>();
    ids.forEach(id => cur.add(id));
    this.store.set(k, cur);
  }
  async trimSeen(_key: SeenKey, _max: number) { /* no-op */ }
}

class RedisStorage implements Storage {
  private client: any;
  constructor() {
    // Lazy import without bundler complaints
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const { Redis } = require("@upstash/redis");
    this.client = new Redis({
      url: process.env.UPSTASH_REDIS_REST_URL!,
      token: process.env.UPSTASH_REDIS_REST_TOKEN!,
    });
  }
  private key({ uid, category }: SeenKey) { return `trivia:seen:${uid}:${category}`; }

  async getSeen(key: SeenKey) {
    const members: string[] = (await this.client.smembers(this.key(key))) ?? [];
    return new Set(members);
  }
  async addSeen(key: SeenKey, ids: string[]) {
    if (!ids.length) return;
    await this.client.sadd(this.key(key), ...ids);
  }
  async trimSeen(key: SeenKey, maxSize: number) {
    const k = this.key(key);
    const size: number = await this.client.scard(k);
    if (size <= maxSize) return;
    // Over-limit: randomly remove until under cap
    const toRemove = size - maxSize;
    // spop removes random members
    await this.client.spop(k, toRemove);
  }
}

export function getStorage(): Storage {
  const useRedis = !!(process.env.UPSTASH_REDIS_REST_URL && process.env.UPSTASH_REDIS_REST_TOKEN);
  return useRedis ? new RedisStorage() : new InMemoryStorage();
}
