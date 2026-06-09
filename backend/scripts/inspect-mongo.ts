/**
 * Inspect the source MongoDB: list every (non-system) database + collection,
 * count docs, print a sample, and dump full collections to scripts/dump/*.json
 * so we can design the Postgres mapping from the real shape.
 *
 *   npx ts-node scripts/inspect-mongo.ts
 *
 * Reads MONGODB_URI from .env.migration (gitignored).
 */
import { config } from 'dotenv';
import { existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { MongoClient } from 'mongodb';

config({ path: join(__dirname, '..', '.env.migration') });
config(); // also fold in a regular .env if present

const SYSTEM_DBS = new Set(['admin', 'local', 'config']);
const DUMP_DIR = join(__dirname, 'dump');
const SAMPLE = 2; // docs to print per collection
const MAX_DUMP = 5000; // safety cap per collection

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('MONGODB_URI missing (set it in .env.migration)');

  const client = new MongoClient(uri);
  await client.connect();
  console.log('Connected to MongoDB.\n');

  if (!existsSync(DUMP_DIR)) mkdirSync(DUMP_DIR, { recursive: true });

  const { databases } = await client.db().admin().listDatabases();
  const dbNames = databases
    .map((d) => d.name)
    .filter((n) => !SYSTEM_DBS.has(n));

  const summary: Array<{ db: string; collection: string; count: number }> = [];

  for (const dbName of dbNames) {
    const db = client.db(dbName);
    const collections = await db.listCollections().toArray();
    for (const { name } of collections) {
      const coll = db.collection(name);
      const count = await coll.countDocuments();
      summary.push({ db: dbName, collection: name, count });

      const docs = await coll.find().limit(MAX_DUMP).toArray();
      const file = join(DUMP_DIR, `${dbName}.${name}.json`);
      writeFileSync(file, JSON.stringify(docs, jsonReplacer, 2));

      console.log(`\n=== ${dbName}.${name} (${count} docs) ===`);
      console.log(`fields: ${fieldList(docs).join(', ') || '(empty)'}`);
      for (const d of docs.slice(0, SAMPLE)) {
        console.log(JSON.stringify(d, jsonReplacer));
      }
    }
  }

  console.log('\n\n========== SUMMARY ==========');
  for (const s of summary) {
    console.log(`${s.db}.${s.collection}: ${s.count}`);
  }
  console.log(`\nFull dumps written to ${DUMP_DIR}`);

  await client.close();
}

/** Union of top-level keys across the sampled docs. */
function fieldList(docs: Record<string, unknown>[]): string[] {
  const keys = new Set<string>();
  for (const d of docs) for (const k of Object.keys(d)) keys.add(k);
  return [...keys];
}

/** Render ObjectId/Date/Buffer readably in JSON. */
function jsonReplacer(_key: string, value: unknown): unknown {
  if (value && typeof value === 'object') {
    const ctor = (value as { constructor?: { name?: string } }).constructor
      ?.name;
    if (ctor === 'ObjectId' || ctor === 'Decimal128' || ctor === 'Long') {
      return String(value);
    }
  }
  return value;
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
