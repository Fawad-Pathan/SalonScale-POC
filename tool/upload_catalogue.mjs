import { readFile } from 'node:fs/promises';
import admin from 'firebase-admin';

const salonId = process.argv[2] || process.env.DEMO_SALON_ID || 'demo_salon';
const catalogueUrl = new URL('../assets/data/products.json', import.meta.url);
const products = JSON.parse(await readFile(catalogueUrl, 'utf8'));

if (!Array.isArray(products)) {
  throw new Error('assets/data/products.json must contain a JSON array.');
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();
const batch = db.batch();
for (const product of products) {
  if (!product.id) {
    throw new Error('Every product needs an id.');
  }
  const ref = db.collection('salons').doc(salonId).collection('products').doc(product.id);
  batch.set(ref, product, { merge: true });
}

await batch.commit();
console.log(`Uploaded ${products.length} products to salons/${salonId}/products.`);
