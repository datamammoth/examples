#!/usr/bin/env python3
"""
Simple webhook listener that receives DataMammoth webhook events.

Verifies the webhook signature and logs events.

Usage:
    pip install flask
    export DM_WEBHOOK_SECRET="whsec_..."
    python webhook_listener.py

Then register this URL as a webhook endpoint in DataMammoth:
    POST /api/v2/webhooks
    {
        "url": "https://your-server.com/webhook",
        "events": ["server.created", "server.terminated", "invoice.paid"],
        "secret": "whsec_..."
    }
"""

import hashlib
import hmac
import json
import os
import sys
from datetime import datetime

from flask import Flask, request, jsonify

app = Flask(__name__)

WEBHOOK_SECRET = os.environ.get("DM_WEBHOOK_SECRET", "")


def verify_signature(payload: bytes, signature: str, secret: str) -> bool:
    """Verify the HMAC-SHA256 webhook signature."""
    if not secret:
        return True  # Skip verification if no secret configured

    expected = hmac.new(
        secret.encode("utf-8"),
        payload,
        hashlib.sha256,
    ).hexdigest()

    # Compare with the signature from the X-DM-Signature header
    # Format: sha256=<hex_digest>
    provided = signature.replace("sha256=", "")
    return hmac.compare_digest(expected, provided)


@app.route("/webhook", methods=["POST"])
def handle_webhook():
    """Handle incoming webhook events from DataMammoth."""
    payload = request.get_data()
    signature = request.headers.get("X-DM-Signature", "")

    # Step 1: Verify signature
    if not verify_signature(payload, signature, WEBHOOK_SECRET):
        print(f"[{datetime.now()}] WARN: Invalid webhook signature")
        return jsonify({"error": "Invalid signature"}), 401

    # Step 2: Parse the event
    event = json.loads(payload)
    event_type = event.get("type", "unknown")
    event_id = event.get("id", "")
    data = event.get("data", {})

    print(f"\n[{datetime.now()}] Received event: {event_type} ({event_id})")
    print(f"  Data: {json.dumps(data, indent=2)}")

    # Step 3: Handle specific event types
    match event_type:
        case "server.created":
            server_id = data.get("server_id")
            ip = data.get("ip_address")
            print(f"  -> New server: {server_id} at {ip}")
            # TODO: Add to monitoring, update DNS, etc.

        case "server.terminated":
            server_id = data.get("server_id")
            print(f"  -> Server terminated: {server_id}")
            # TODO: Remove from monitoring, clean up DNS

        case "invoice.paid":
            invoice_id = data.get("invoice_id")
            amount = data.get("amount")
            print(f"  -> Invoice paid: {invoice_id} (${amount})")
            # TODO: Send confirmation email, update accounting

        case "invoice.overdue":
            invoice_id = data.get("invoice_id")
            print(f"  -> Invoice overdue: {invoice_id}")
            # TODO: Send reminder, suspend services if needed

        case _:
            print(f"  -> Unhandled event type: {event_type}")

    # Always return 200 to acknowledge receipt
    return jsonify({"received": True}), 200


@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint."""
    return jsonify({"status": "ok"}), 200


if __name__ == "__main__":
    if not WEBHOOK_SECRET:
        print("WARNING: DM_WEBHOOK_SECRET not set -- signature verification disabled")

    print("Starting webhook listener on http://0.0.0.0:8080")
    app.run(host="0.0.0.0", port=8080, debug=True)
