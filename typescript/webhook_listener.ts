#!/usr/bin/env npx ts-node
/**
 * Simple webhook listener using Express that receives DataMammoth events.
 *
 * Usage:
 *   npm install express
 *   export DM_WEBHOOK_SECRET="whsec_..."
 *   npx ts-node webhook_listener.ts
 */

import express from "express";
import crypto from "crypto";

const app = express();
const WEBHOOK_SECRET = process.env.DM_WEBHOOK_SECRET || "";

// Parse raw body for signature verification
app.use("/webhook", express.raw({ type: "application/json" }));
app.use(express.json());

/**
 * Verify the HMAC-SHA256 webhook signature.
 */
function verifySignature(
  payload: Buffer,
  signature: string,
  secret: string
): boolean {
  if (!secret) return true; // Skip if no secret configured

  const expected = crypto
    .createHmac("sha256", secret)
    .update(payload)
    .digest("hex");

  const provided = signature.replace("sha256=", "");
  return crypto.timingSafeEqual(
    Buffer.from(expected, "hex"),
    Buffer.from(provided, "hex")
  );
}

app.post("/webhook", (req, res) => {
  const payload = req.body as Buffer;
  const signature = (req.headers["x-dm-signature"] as string) || "";

  // Step 1: Verify signature
  if (!verifySignature(payload, signature, WEBHOOK_SECRET)) {
    console.warn(`[${new Date().toISOString()}] WARN: Invalid webhook signature`);
    return res.status(401).json({ error: "Invalid signature" });
  }

  // Step 2: Parse the event
  const event = JSON.parse(payload.toString());
  const { type, id, data } = event;

  console.log(`\n[${new Date().toISOString()}] Received: ${type} (${id})`);
  console.log(`  Data: ${JSON.stringify(data, null, 2)}`);

  // Step 3: Handle specific event types
  switch (type) {
    case "server.created":
      console.log(`  -> New server: ${data.server_id} at ${data.ip_address}`);
      break;
    case "server.terminated":
      console.log(`  -> Server terminated: ${data.server_id}`);
      break;
    case "invoice.paid":
      console.log(`  -> Invoice paid: ${data.invoice_id} ($${data.amount})`);
      break;
    default:
      console.log(`  -> Unhandled: ${type}`);
  }

  res.json({ received: true });
});

app.get("/health", (_req, res) => {
  res.json({ status: "ok" });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  if (!WEBHOOK_SECRET) {
    console.warn("WARNING: DM_WEBHOOK_SECRET not set -- signature verification disabled");
  }
  console.log(`Webhook listener running on http://0.0.0.0:${PORT}`);
});
