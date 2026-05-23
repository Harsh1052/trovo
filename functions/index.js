/**
 * Cloud Functions for HunterMania (Trovo)
 *
 * onPurchaseWebhook — HTTPS endpoint for RevenueCat server-to-server webhooks.
 *
 * Setup:
 *   firebase functions:config:set revenuecat.webhook_secret="YOUR_SECRET"
 *
 * RevenueCat webhook URL (after deploy):
 *   https://asia-south1-trovo-prod.cloudfunctions.net/onPurchaseWebhook
 */

const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { logger } = require("firebase-functions");

initializeApp();
const db = getFirestore();

// Secret stored in Google Cloud Secret Manager (set via Firebase CLI).
const webhookSecret = defineSecret("REVENUECAT_WEBHOOK_SECRET");

/**
 * Extracts a hunt ID from a RevenueCat product identifier.
 *
 * Convention: product IDs follow the pattern `hunt_<huntId>` or
 * `com.trovo.app.hunt_<huntId>`. We take everything after the last
 * `hunt_` prefix.
 *
 * Examples:
 *   "hunt_panchvati_garden"       → "panchvati_garden"
 *   "com.trovo.app.hunt_sula"     → "sula"
 *   "premium_monthly"             → null  (not a hunt product)
 */
function extractHuntId(productId) {
  if (!productId) return null;
  const match = productId.match(/hunt_(.+)$/);
  return match ? match[1] : null;
}

exports.onPurchaseWebhook = onRequest(
  {
    region: "asia-south1",
    secrets: [webhookSecret],
  },
  async (req, res) => {
    // ── Method check ──────────────────────────────────────────────────────
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    // ── Auth check ────────────────────────────────────────────────────────
    const authHeader = req.get("Authorization");
    const expectedToken = `Bearer ${webhookSecret.value()}`;

    if (!authHeader || authHeader !== expectedToken) {
      logger.warn("Unauthorized webhook attempt", {
        ip: req.ip,
        authPresent: !!authHeader,
      });
      res.status(401).send("Unauthorized");
      return;
    }

    // ── Parse body ────────────────────────────────────────────────────────
    const event = req.body;

    if (!event || !event.event) {
      logger.warn("Malformed webhook payload", { body: req.body });
      res.status(400).send("Bad Request");
      return;
    }

    const eventType = event.event.type;
    const appUserId = event.event.app_user_id;
    const productId = event.event.product_id;

    logger.info("RevenueCat webhook received", { eventType, appUserId, productId });

    if (!appUserId) {
      logger.warn("Missing app_user_id");
      res.status(400).send("Missing app_user_id");
      return;
    }

    const huntId = extractHuntId(productId);

    // ── Handle event types ────────────────────────────────────────────────
    try {
      const userRef = db.collection("users").doc(appUserId);

      switch (eventType) {
        case "INITIAL_PURCHASE":
        case "NON_RENEWING_PURCHASE":
        case "RENEWAL": {
          if (!huntId) {
            logger.info("Non-hunt purchase, skipping array update", { productId });
            res.status(200).send("OK — no hunt mapping");
            return;
          }

          await userRef.update({
            purchasedHuntIds: FieldValue.arrayUnion(huntId),
            updatedAt: FieldValue.serverTimestamp(),
          });

          logger.info("Added hunt to purchasedHuntIds", { appUserId, huntId });
          break;
        }

        case "CANCELLATION":
        case "REFUND": {
          if (!huntId) {
            logger.info("Non-hunt refund, skipping array update", { productId });
            res.status(200).send("OK — no hunt mapping");
            return;
          }

          await userRef.update({
            purchasedHuntIds: FieldValue.arrayRemove(huntId),
            updatedAt: FieldValue.serverTimestamp(),
          });

          logger.info("Removed hunt from purchasedHuntIds", { appUserId, huntId });
          break;
        }

        default:
          logger.info("Unhandled event type, acknowledging", { eventType });
      }

      res.status(200).send("OK");
    } catch (error) {
      logger.error("Webhook processing failed", { error: error.message, appUserId });
      // Return 200 anyway to prevent RevenueCat from retrying endlessly.
      // The error is logged for manual investigation.
      res.status(200).send("OK — logged error");
    }
  }
);
