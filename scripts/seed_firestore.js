#!/usr/bin/env node

/**
 * Seed production Firestore with sample HunterMania data.
 *
 * ── Setup ─────────────────────────────────────────────────────────────────────
 *   1. Download a service account key from:
 *      Firebase Console → Project Settings → Service accounts → Generate new key
 *      Save it as scripts/serviceAccountKey.json  (already in .gitignore)
 *
 *   2. cd scripts && npm install
 *   3. npm run seed
 *
 * This script is IDEMPOTENT — all document IDs are fixed, so re-running
 * overwrites existing docs instead of creating duplicates.
 */

const { initializeApp, cert } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const path = require("path");
const fs = require("fs");

// ── Initialise Firebase Admin ─────────────────────────────────────────────────

const serviceAccountPath = path.join(__dirname, "serviceAccountKey.json");

if (fs.existsSync(serviceAccountPath)) {
  initializeApp({ credential: cert(require(serviceAccountPath)), projectId: "trovo-prod-app" });
  console.log("🔑  Using serviceAccountKey.json");
} else {
  console.log("ℹ️  No serviceAccountKey.json found — using projectId: trovo-prod-app");
  initializeApp({ projectId: "trovo-prod-app" });
}

const db = getFirestore();

// ── Load seed data ─────────────────────────────────────────────────────────────

const seedData = JSON.parse(
  fs.readFileSync(path.join(__dirname, "seed_data.json"), "utf8")
);

// ── Helpers ───────────────────────────────────────────────────────────────────

/** Convert an ISO-8601 string to a Firestore Timestamp. */
function ts(isoString) {
  if (!isoString) return null;
  return Timestamp.fromDate(new Date(isoString));
}

/**
 * Convert a plain object whose values are ISO-8601 strings into one whose
 * values are Firestore Timestamps.  Used for checkpointTimestamps.
 */
function tsMap(obj) {
  if (!obj) return {};
  return Object.fromEntries(
    Object.entries(obj).map(([k, v]) => [k, ts(v)])
  );
}

// ── Seed ──────────────────────────────────────────────────────────────────────

async function seed() {
  let batch = db.batch();
  let opCount = 0;

  function set(ref, data) {
    if (opCount === 499) {
      throw new Error(
        "Batch limit approached — split into multiple batches for larger datasets."
      );
    }
    batch.set(ref, data);
    opCount++;
  }

  // ── users ──────────────────────────────────────────────────────────────────
  if (seedData.users) {
    console.log("\n👤  Seeding users…");
    for (const user of seedData.users) {
      const ref = db.collection("users").doc(user._docId);
      set(ref, {
        displayName: user.displayName,
        email: user.email ?? null,
        photoUrl: user.photoUrl ?? null,
        completedHunts: user.completedHunts ?? [],
        purchasedHunts: user.purchasedHunts ?? [],
        createdAt: ts(user.createdAt),
        lastActiveAt: ts(user.lastActiveAt),
        updatedAt: Timestamp.now(),
      });
      console.log(`   ✅  ${user.displayName}  (${user._docId})`);
    }
  }

  // ── hunts ──────────────────────────────────────────────────────────────────
  console.log("\n🗺️   Seeding hunts…");
  for (const hunt of seedData.hunts) {
    const huntRef = db.collection("hunts").doc(hunt._docId);
    set(huntRef, {
      title: hunt.title,
      description: hunt.description,
      city: hunt.city,
      gardenName: hunt.gardenName,
      difficulty: hunt.difficulty,
      durationMinutes: hunt.durationMinutes,
      checkpointCount: hunt.checkpointCount,
      isFree: hunt.isFree,
      price: hunt.price,
      coverImageUrl: hunt.coverImageUrl ?? "",
      startLatitude: hunt.startLatitude,
      startLongitude: hunt.startLongitude,
      isActive: hunt.isActive,
      createdAt: ts(hunt.createdAt),
      updatedAt: Timestamp.now(),
    });
    console.log(`   ✅  "${hunt.title}"  (${hunt._docId})`);

    // ── checkpoints (sub-collection) ────────────────────────────────────────
    if (seedData.checkpoints && seedData.checkpoints[hunt._docId]) {
      const checkpoints = seedData.checkpoints[hunt._docId];
      console.log(`      📍  Seeding ${checkpoints.length} checkpoints…`);
      for (const cp of checkpoints) {
        const cpRef = huntRef.collection("checkpoints").doc(cp._docId);
        set(cpRef, {
          huntId: cp.huntId,
          orderIndex: cp.orderIndex,
          clueText: cp.clueText,
          hintText: cp.hintText ?? "",
          latitude: cp.latitude,
          longitude: cp.longitude,
          type: cp.type,
          answer: cp.answer ?? null,
          unlockRadius: cp.unlockRadius ?? 20,
          funFact: cp.funFact ?? null,
        });
        console.log(`         ✅  orderIndex ${cp.orderIndex} — ${cp._docId}`);
      }
    }
  }

  // ── huntProgress ───────────────────────────────────────────────────────────
  if (seedData.huntProgress) {
    console.log("\n📊  Seeding huntProgress…");
    for (const progress of seedData.huntProgress) {
      const ref = db.collection("huntProgress").doc(progress._docId);
      set(ref, {
        userId: progress.userId,
        huntId: progress.huntId,
        status: progress.status,
        currentCheckpointIndex: progress.currentCheckpointIndex,
        hintsUsed: progress.hintsUsed,
        startedAt: ts(progress.startedAt),
        completedAt: ts(progress.completedAt),
        checkpointTimestamps: tsMap(progress.checkpointTimestamps),
        updatedAt: Timestamp.now(),
      });
      console.log(`   ✅  ${progress._docId}  (status: ${progress.status})`);
    }
  }

  // ── Commit ─────────────────────────────────────────────────────────────────
  await batch.commit();
  console.log(`\n🎉  Done — ${opCount} document(s) written to PRODUCTION Firestore.\n`);
}

seed().catch((err) => {
  console.error("\n❌  Seeding failed:", err.message ?? err);
  process.exit(1);
});
