import express from "express";
import CampRequest from "../models/CampRequest.js";
import MoneyDonation from "../models/MoneyDonation.js";
import DonationRecord from "../models/DonationRecord.js";

const router = express.Router();

// Donate items
router.post("/donate-item", async (req, res) => {
  try {
    const { requestId, donateQty } = req.body;

    const request = await CampRequest.findById(requestId);
    if (!request || request.remainingQty <= 0) {
      return res.status(400).json({ message: "Invalid or fulfilled request" });
    }

    // Validate donation amount
    if (donateQty > request.remainingQty) {
      return res.status(400).json({
        message: `Cannot donate more than remaining quantity (${request.remainingQty})`
      });
    }

    // 1. Deduct from Request (optimistically - shows donor it's being processed)
    request.remainingQty -= donateQty;

    if (request.remainingQty <= 0) {
      request.remainingQty = 0;
    }

    await request.save();

    // 2. Create Donation Record as PENDING
    // Camp manager will mark as Received/Not Received

    await DonationRecord.create({
      campId: request.campId,
      donorName: "Ananya", // Hardcoded for demo, or pass from req.body
      itemName: request.itemName,
      quantity: donateQty,
      unit: request.unit || "units",
      status: "Pending" // Changed from "Received"
    });

    // NOTE: Inventory is NOT updated here anymore
    // It will be updated when camp manager clicks "Received" button

    res.json({
      message: "Donation recorded successfully. Awaiting camp confirmation.",
      remaining: request.remainingQty
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Donate money (mock)
router.post("/donate-money", async (req, res) => {
  const donation = new MoneyDonation({
    donorId: req.body.donorId,
    campId: req.body.campId,
    amount: req.body.amount,
    paymentStatus: "SUCCESS"
  });

  await donation.save();
  res.json({ message: "Money donation successful" });
});

export default router;
