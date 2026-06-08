/** Storage bucket names (mirrors the Flutter `Buckets`). */
export const Buckets = {
  printFiles: 'print-files', // private
  printPreviews: 'print-previews', // public
  mockups: 'mockups', // public
  productTemplates: 'product-templates', // public
  signatures: 'signatures', // private
} as const;

export const PUBLIC_BUCKETS: string[] = [
  Buckets.printPreviews,
  Buckets.mockups,
  Buckets.productTemplates,
];

/** Buckets a signed-in user may upload to directly. */
export const UPLOAD_BUCKETS: string[] = [
  Buckets.printFiles,
  Buckets.printPreviews,
  Buckets.signatures,
];

export const EXT_BY_MIME: Record<string, string> = {
  'image/png': 'png',
  'image/jpeg': 'jpg',
};
