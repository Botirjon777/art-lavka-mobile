/**
 * Local seed: categories + product types with print-zone metadata (SPEC §6).
 * Run with `npm run db:seed` (needs a migrated DATABASE_URL).
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main(): Promise<void> {
  const categories = [
    { slug: 'gamers', nameRu: 'Геймеры', nameUz: 'Geymerlar', nameEn: 'Gamers', sortOrder: 1 },
    { slug: 'memes', nameRu: 'Мемы', nameUz: 'Memlar', nameEn: 'Memes', sortOrder: 2 },
    { slug: 'funny', nameRu: 'Смешное', nameUz: 'Kulgili', nameEn: 'Funny', sortOrder: 3 },
    { slug: 'anime', nameRu: 'Аниме', nameUz: 'Anime', nameEn: 'Anime', sortOrder: 4 },
  ];
  for (const c of categories) {
    await prisma.category.upsert({
      where: { slug: c.slug },
      update: {},
      create: c,
    });
  }

  const products = [
    {
      slug: 'tshirt',
      nameRu: 'Футболка',
      nameUz: 'Futbolka',
      nameEn: 'T-shirt',
      baseCost: 60000n,
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      variants: [
        {
          color: 'white',
          template_url: 'product-templates/tee-white-front.png',
          print_zone: { x: 210, y: 180, w: 360, h: 480, rotation: 0 },
          warp: 'none',
        },
        {
          color: 'black',
          template_url: 'product-templates/tee-black-front.png',
          print_zone: { x: 210, y: 180, w: 360, h: 480, rotation: 0 },
          warp: 'none',
        },
      ],
    },
    {
      slug: 'hoodie',
      nameRu: 'Худи',
      nameUz: 'Hudi',
      nameEn: 'Hoodie',
      baseCost: 130000n,
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      variants: [
        {
          color: 'black',
          template_url: 'product-templates/hoodie-black-front.png',
          print_zone: { x: 230, y: 260, w: 320, h: 380, rotation: 0 },
          warp: 'none',
        },
      ],
    },
    {
      slug: 'cap',
      nameRu: 'Кепка',
      nameUz: 'Kepka',
      nameEn: 'Cap',
      baseCost: 50000n,
      sizes: ['one-size'],
      variants: [
        {
          color: 'black',
          template_url: 'product-templates/cap-black-front.png',
          print_zone: { x: 260, y: 210, w: 200, h: 140, rotation: 0 },
          warp: 'none',
        },
      ],
    },
    {
      slug: 'cup',
      nameRu: 'Кружка',
      nameUz: 'Krujka',
      nameEn: 'Cup',
      baseCost: 45000n,
      sizes: ['one-size'],
      variants: [
        {
          color: 'white',
          template_url: 'product-templates/cup-white.png',
          print_zone: { x: 300, y: 160, w: 260, h: 300, rotation: 0 },
          warp: 'none',
        },
      ],
    },
  ];
  for (const p of products) {
    await prisma.productType.upsert({
      where: { slug: p.slug },
      update: {},
      create: p,
    });
  }

  console.log(`Seeded ${categories.length} categories, ${products.length} product types.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
