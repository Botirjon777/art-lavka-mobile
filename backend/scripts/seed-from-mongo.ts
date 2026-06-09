/**
 * Migrate the legacy artlavka.uz catalog (MongoDB) into our marketplace
 * Postgres schema, idempotently. Images already live on the same Cloudinary
 * account, so we reference their URLs directly (no re-upload).
 *
 *   npx ts-node scripts/seed-from-mongo.ts --dry   # report only, no writes
 *   npx ts-node scripts/seed-from-mongo.ts         # write to DATABASE_URL
 *
 * Mapping:
 *   printcategories → Category        products → ProductType
 *   prints          → Design (+ DesignCategory + Listing on each active product)
 *   galleries       → Banner (inactive; lifestyle/showcase shots)
 * All legacy prints are attributed to one verified shop ("ART-LAVKA").
 *
 * Reads MONGODB_URI from .env.migration; writes via Prisma's DATABASE_URL.
 */
import { config } from 'dotenv';
import { createHash } from 'node:crypto';
import { join } from 'node:path';
import { PrismaClient } from '@prisma/client';
import { MongoClient } from 'mongodb';

config({ path: join(__dirname, '..', '.env.migration') });
config();

const DRY = process.argv.includes('--dry');
const SHOP = {
  phone: '+998900000010',
  slug: 'art-lavka',
  displayName: 'ART-LAVKA',
  bio: 'Эксклюзивные дизайнерские принты ART-LAVKA.',
};
const DEFAULT_ROYALTY = 20_000n; // designer cut per sale (within bounds)

const prisma = new PrismaClient();

/** Deterministic ObjectId(24-hex) → UUID so re-runs are idempotent. */
function oidToUuid(oid: unknown): string {
  const h = createHash('md5').update(String(oid)).digest('hex'); // 32 hex
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-4${h.slice(13, 16)}-8${h.slice(17, 20)}-${h.slice(20, 32)}`;
}

function slugify(s: string): string {
  return (
    String(s)
      .toLowerCase()
      .trim()
      .replace(/[“”‘’'"]/g, '')
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '') || 'item'
  );
}

interface Translated {
  ru?: { name?: string; label?: string };
  uz?: { name?: string; label?: string };
  en?: { name?: string; label?: string };
}
function names(t: Translated | undefined, fallback: string) {
  return {
    nameRu: t?.ru?.name ?? t?.ru?.label ?? fallback,
    nameUz: t?.uz?.name ?? t?.uz?.label ?? fallback,
    nameEn: t?.en?.name ?? t?.en?.label ?? fallback,
  };
}

async function main() {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('MONGODB_URI missing (set it in .env.migration)');

  const mongo = new MongoClient(uri);
  await mongo.connect();
  const db = mongo.db('test');
  console.log(`Source: MongoDB test  |  Target: Postgres${DRY ? '  (DRY RUN)' : ''}\n`);

  const printCategories = await db.collection('printcategories').find().toArray();
  const products = await db.collection('products').find().toArray();
  const prints = await db.collection('prints').find().toArray();
  const galleries = await db.collection('galleries').find().toArray();

  // 0) Wipe the existing catalog + transactional test data (keep admin) ----
  // The target only holds demo/test rows; real orders live in Mongo and are
  // not migrated. Order children must go first (RESTRICT FKs to designs).
  if (!DRY) {
    await prisma.review.deleteMany({});
    await prisma.ledgerEntry.deleteMany({});
    await prisma.cartItem.deleteMany({});
    await prisma.orderItem.deleteMany({});
    await prisma.order.deleteMany({});
    await prisma.payout.deleteMany({});
    await prisma.design.deleteMany({}); // cascades listings + design_categories
    await prisma.banner.deleteMany({});
    await prisma.category.deleteMany({});
    await prisma.productType.deleteMany({});
    await prisma.designerProfile.deleteMany({});
    await prisma.user.deleteMany({ where: { phone: '+998900000001' } });
    console.log('cleanup   wiped catalog + transactional test data (admin kept)\n');
  }

  // 1) Categories ----------------------------------------------------------
  let sort = 1;
  for (const c of printCategories) {
    const slug = c.slug || slugify(c.name);
    const data = { slug, ...names(c.translations, c.name), sortOrder: sort++ };
    console.log(`category  ${slug}  (${data.nameEn})`);
    if (!DRY) {
      await prisma.category.upsert({ where: { slug }, update: data, create: data });
    }
  }

  // 2) Product types -------------------------------------------------------
  const activeProductSlugs: string[] = [];
  const seenSlugs = new Set<string>();
  for (const p of products) {
    let slug = slugify(p.translations?.en?.name || p.name);
    while (seenSlugs.has(slug)) slug = `${slug}-x`;
    seenSlugs.add(slug);

    const baseCost = BigInt(Math.round(p.price ?? p.colors?.[0]?.variants?.[0]?.price ?? 100000));
    const variants = (p.colors ?? []).map((col: Record<string, unknown>) => ({
      color: col.name,
      hex: col.hex,
      template_url: p.image ?? null,
      sizes: ((col.variants as Record<string, unknown>[]) ?? []).map((v) => ({
        size: v.size,
        price: v.price,
        old_price: v.oldPrice,
        stock: v.stock,
      })),
    }));
    const data = {
      slug,
      ...names(p.translations, p.name),
      baseCost,
      sizes: p.sizes ?? [],
      variants,
    };
    console.log(`product   ${slug}  base=${baseCost}  active=${p.active}`);
    if (p.active) activeProductSlugs.push(slug);
    if (!DRY) {
      await prisma.productType.upsert({ where: { slug }, update: data, create: data });
    }
  }
  if (activeProductSlugs.length === 0 && products[0]) {
    activeProductSlugs.push(slugify(products[0].translations?.en?.name || products[0].name));
  }

  // 3) Shop (one verified seller owns the legacy catalog) ------------------
  let shopUserId = oidToUuid('art-lavka-shop-user');
  if (!DRY) {
    const user = await prisma.user.upsert({
      where: { phone: SHOP.phone },
      update: { role: 'designer' },
      create: { phone: SHOP.phone, fullName: SHOP.displayName, role: 'designer' },
    });
    shopUserId = user.id;
    await prisma.designerProfile.upsert({
      where: { userId: user.id },
      update: { kycStatus: 'verified', displayName: SHOP.displayName, bio: SHOP.bio },
      create: {
        userId: user.id,
        slug: SHOP.slug,
        displayName: SHOP.displayName,
        bio: SHOP.bio,
        kycStatus: 'verified',
        payoutMethod: 'card',
      },
    });
  }
  console.log(`\nshop      ${SHOP.displayName} (${SHOP.slug})  owns all prints`);

  // resolve product type + category ids (skip in dry run)
  const productTypeIds = DRY
    ? []
    : (
        await prisma.productType.findMany({
          where: { slug: { in: activeProductSlugs } },
          select: { id: true },
        })
      ).map((r) => r.id);
  const catBySlug = new Map<string, string>();
  if (!DRY) {
    for (const c of await prisma.category.findMany({ select: { id: true, slug: true } })) {
      catBySlug.set(c.slug, c.id);
    }
  }

  // 4) Prints → Designs + DesignCategory + Listings ------------------------
  let designCount = 0;
  let listingCount = 0;
  for (const pr of prints) {
    const id = oidToUuid(pr._id);
    const preview = pr.frontImagePreview || pr.frontImage || '';
    const data = {
      designerId: shopUserId,
      title: pr.name,
      previewUrl: preview,
      printFilePath: pr.frontImage || preview,
      widthPx: 3000,
      heightPx: 3000,
      status: (pr.active ? 'approved' : 'draft') as 'approved' | 'draft',
    };
    designCount++;
    if (!DRY) {
      await prisma.design.upsert({ where: { id }, update: { status: data.status }, create: { id, ...data } });
      const catId = pr.category ? catBySlug.get(pr.category) : undefined;
      if (catId) {
        await prisma.designCategory.createMany({
          data: [{ designId: id, categoryId: catId }],
          skipDuplicates: true,
        });
      }
      for (const ptId of productTypeIds) {
        await prisma.listing.upsert({
          where: { designId_productTypeId: { designId: id, productTypeId: ptId } },
          update: { active: pr.active ?? true },
          create: { designId: id, productTypeId: ptId, royalty: DEFAULT_ROYALTY, active: pr.active ?? true },
        });
        listingCount++;
      }
    }
  }
  console.log(`prints    ${designCount} designs → ${DRY ? '(skipped)' : listingCount} listings`);

  // 5) Galleries → inactive banners (showcase shots, available to enable) --
  let galleryCount = 0;
  for (const g of galleries) {
    if (!g.image) continue;
    const id = oidToUuid(g._id);
    galleryCount++;
    if (!DRY) {
      await prisma.banner.upsert({
        where: { id },
        update: { imageUrl: g.image },
        create: { id, imageUrl: g.image, linkType: 'none', active: false, sortOrder: 100 },
      });
    }
  }
  console.log(`galleries ${galleryCount} → inactive banners`);

  console.log(`\n${DRY ? 'DRY RUN complete — no writes made.' : 'Seed complete.'}`);
  await mongo.close();
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
