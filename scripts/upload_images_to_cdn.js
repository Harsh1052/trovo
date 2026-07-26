const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const API_KEY = '6d207e02198a847aa98d0a2a901485a5';

const imageFiles = [
  { docId: 'sdh_cp_01', file: 'assets/images/surat_cp1_diamond_gate.png' },
  { docId: 'sdh_cp_02', file: 'assets/images/surat_cp2_banyan_canopy.png' },
  { docId: 'sdh_cp_03', file: 'assets/images/surat_cp3_tapi_lookout.png' },
  { docId: 'sdh_cp_04', file: 'assets/images/surat_cp4_merchant_cipher.png' },
  { docId: 'sdh_cp_05', file: 'assets/images/surat_cp5_royal_vault.png' },
];

async function uploadFile(filePath) {
  const fullPath = path.resolve(__dirname, '..', filePath);
  console.log(`📡 Uploading ${filePath} to Cloud CDN...`);
  
  const cmd = `curl -s -F "key=${API_KEY}" -F "action=upload" -F "source=@${fullPath}" -F "format=json" https://freeimage.host/api/1/upload`;
  const output = execSync(cmd).toString();
  const json = JSON.parse(output);
  
  if (json && json.image && json.image.url) {
    console.log(`   ✅ Hosted URL: ${json.image.url}`);
    return json.image.url;
  } else {
    throw new Error(`Upload failed: ${output}`);
  }
}

async function run() {
  try {
    const urls = {};
    for (const item of imageFiles) {
      urls[item.docId] = await uploadFile(item.file);
    }
    
    console.log('\n🎉 ALL IMAGES HOSTED ON CLOUD CDN:');
    console.log(JSON.stringify(urls, null, 2));

    fs.writeFileSync(path.resolve(__dirname, 'cdn_urls.json'), JSON.stringify(urls, null, 2));
  } catch (err) {
    console.error('❌ Error during CDN upload:', err);
  }
}

run();
