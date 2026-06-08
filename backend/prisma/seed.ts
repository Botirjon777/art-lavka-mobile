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

  // --- Demo storefront (so the catalog/home actually show products) ---------
  const demoUser = await prisma.user.upsert({
    where: { phone: '+998900000001' },
    update: { role: 'designer' },
    create: { phone: '+998900000001', fullName: 'Demo Studio', role: 'designer' },
  });
  await prisma.designerProfile.upsert({
    where: { userId: demoUser.id },
    update: { kycStatus: 'verified' },
    create: {
      userId: demoUser.id,
      slug: 'demo-studio',
      displayName: 'Demo Studio',
      kycStatus: 'verified',
      payoutMethod: 'card',
    },
  });

  const tshirt = await prisma.productType.findUnique({ where: { slug: 'tshirt' } });
  const cup = await prisma.productType.findUnique({ where: { slug: 'cup' } });

  const demoDesigns = [
    { id: '00000000-0000-4000-8000-0000000000d1', title: 'Pixel Cat', cat: 'gamers' },
    { id: '00000000-0000-4000-8000-0000000000d2', title: 'Doge Meme', cat: 'memes' },
    { id: '00000000-0000-4000-8000-0000000000d3', title: 'Laughing Sun', cat: 'funny' },
    { id: '00000000-0000-4000-8000-0000000000d4', title: 'Anime Wave', cat: 'anime' },
  ];

  for (const d of demoDesigns) {
    await prisma.design.upsert({
      where: { id: d.id },
      update: { status: 'approved' },
      create: {
        id: d.id,
        designerId: demoUser.id,
        title: d.title,
        description: 'Demo print',
        previewUrl: `https://picsum.photos/seed/${d.id}/600/600`,
        printFilePath: 'print-files/demo.png',
        widthPx: 3000,
        heightPx: 3000,
        status: 'approved',
      },
    });
    const category = await prisma.category.findUnique({ where: { slug: d.cat } });
    if (category) {
      await prisma.designCategory.createMany({
        data: [{ designId: d.id, categoryId: category.id }],
        skipDuplicates: true,
      });
    }
    for (const pt of [tshirt, cup]) {
      if (!pt) continue;
      await prisma.listing.upsert({
        where: { designId_productTypeId: { designId: d.id, productTypeId: pt.id } },
        update: { active: true },
        create: {
          designId: d.id,
          productTypeId: pt.id,
          royalty: pt.slug === 'cup' ? 15000n : 20000n,
          active: true,
        },
      });
    }
  }

  console.log(
    `Seeded ${categories.length} categories, ${products.length} product types, ` +
      `${demoDesigns.length} demo designs (Demo Studio).`,
  );
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
