const fs = require('fs');
const path = require('path');
const https = require('https');

const API_KEY = 'AIzaSyAJl2ZMl0d-ZOMWtPPzPW8KYM3esLD0YUg';
const PROJECT_ID = 'trovo-prod-app';
const BASE_URL = `firestore.googleapis.com`;

const seedData = JSON.parse(
  fs.readFileSync(path.join(__dirname, 'seed_data.json'), 'utf8')
);

function convertToFirestoreFields(obj) {
  const fields = {};
  for (const [key, value] of Object.entries(obj)) {
    if (key.startsWith('_')) continue; // Skip internal fields like _docId
    if (typeof value === 'string') {
      fields[key] = { stringValue: value };
    } else if (typeof value === 'number') {
      if (Number.isInteger(value)) {
        fields[key] = { integerValue: value.toString() };
      } else {
        fields[key] = { doubleValue: value };
      }
    } else if (typeof value === 'boolean') {
      fields[key] = { booleanValue: value };
    } else if (value === null) {
      fields[key] = { nullValue: null };
    } else if (Array.isArray(value)) {
      fields[key] = {
        arrayValue: {
          values: value.map((v) => ({ stringValue: v })),
        },
      };
    }
  }
  return fields;
}

function writeDoc(documentPath, data) {
  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      fields: convertToFirestoreFields(data),
    });

    const options = {
      hostname: BASE_URL,
      port: 443,
      path: `/v1/projects/${PROJECT_ID}/databases/(default)/documents/${documentPath}?key=${API_KEY}`,
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
      },
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(body));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${body}`));
        }
      });
    });

    req.on('error', (e) => reject(e));
    req.write(postData);
    req.end();
  });
}

async function uploadAll() {
  console.log('🚀 Starting Cloud Firestore REST Seeding for project: trovo-prod-app...\n');

  for (const hunt of seedData.hunts) {
    console.log(`🗺️ Uploading hunt: "${hunt.title}" (${hunt._docId})...`);
    try {
      await writeDoc(`hunts/${hunt._docId}`, hunt);
      console.log(`   ✅  Successfully written hunt document: hunts/${hunt._docId}`);
    } catch (err) {
      console.error(`   ❌ Failed writing hunt ${hunt._docId}:`, err.message);
    }

    if (seedData.checkpoints && seedData.checkpoints[hunt._docId]) {
      const cps = seedData.checkpoints[hunt._docId];
      console.log(`   📍 Uploading ${cps.length} checkpoints for ${hunt._docId}...`);
      for (const cp of cps) {
        try {
          await writeDoc(`hunts/${hunt._docId}/checkpoints/${cp._docId}`, cp);
          console.log(`      ✅ Written checkpoint: ${cp._docId}`);
        } catch (err) {
          console.error(`      ❌ Failed checkpoint ${cp._docId}:`, err.message);
        }
      }
    }
  }

  console.log('\n🎉 ALL HUNTS AND CHECKPOINTS UPLOADED TO CLOUD FIRESTORE SUCCESSFULLY!');
}

uploadAll();
