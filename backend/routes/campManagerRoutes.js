import express from "express";
import CampRequest from "../models/CampRequest.js";
import DonationRecord from "../models/DonationRecord.js";
import Inventory from "../models/Inventory.js";

const router = express.Router();

// Create camp request
router.post("/", async (req, res) => {
    const { campId, campName, itemName, requiredQty, unit, category, priority } = req.body;
    try {
        const doc = await CampRequest.create({
            campId,
            campName,
            itemName,
            requiredQty,
            remainingQty: requiredQty,
            status: "Pending",
            unit,
            category,
            priority,
        });
        res.status(201).json(doc);
    } catch (err) {
        console.error("Create camp request error:", err);
        res.status(500).json({ message: "Failed to create camp request" });
    }
});

// Get donation history for a camp
router.get("/donations/:campId", async (req, res) => {
    try {
        const history = await DonationRecord.find({ campId: req.params.campId }).sort({ donatedAt: -1 });
        res.json(history);
    } catch (err) {
        console.error("Fetch donations error:", err);
        res.status(500).json({ message: "Failed to fetch donations" });
    }
});

// Mark donation as physically received
router.put("/donations/:donationId/receive", async (req, res) => {
    try {
        const { donationId } = req.params;

        // 1. Find and update donation
        const donation = await DonationRecord.findById(donationId);
        if (!donation) {
            return res.status(404).json({ message: "Donation not found" });
        }

        if (donation.status === "Received") {
            return res.status(400).json({ message: "Already marked as received" });
        }

        donation.status = "Received";
        donation.receivedAt = new Date();
        await donation.save();

        // 2. Update inventory
        let inventory = await Inventory.findOne({
            campId: donation.campId,
            itemName: donation.itemName
        });

        if (inventory) {
            inventory.quantity += donation.quantity;
            inventory.lastUpdated = new Date();
            await inventory.save();
        } else {
            inventory = await Inventory.create({
                campId: donation.campId,
                itemName: donation.itemName,
                quantity: donation.quantity
            });
        }

        // 3. Check CampRequest status (already reduced when donated)
        const request = await CampRequest.findOne({
            campId: donation.campId,
            itemName: donation.itemName,
            status: { $in: ["Pending", "open", "Open"] }
        });

        if (request) {
            // remainingQty was already reduced when donor donated
            // Just check if we should mark as fulfilled
            if (request.remainingQty === 0) {
                request.status = "Fulfilled";
                await request.save();
            }
        }

        console.log(`✅ Donation received: ${donation.itemName} - ${donation.quantity}${donation.unit}`);

        res.json({
            message: "Donation marked as received",
            newInventory: inventory.quantity,
            remainingNeeded: request?.remainingQty || 0
        });
    } catch (err) {
        console.error("Mark received error:", err);
        res.status(500).json({ message: "Failed to mark as received" });
    }
});

// Mark donation as NOT received (didn't arrive)
router.put("/donations/:donationId/not-receive", async (req, res) => {
    try {
        const { donationId } = req.params;

        // Find and update donation
        const donation = await DonationRecord.findById(donationId);
        if (!donation) {
            return res.status(404).json({ message: "Donation not found" });
        }

        if (donation.status !== "Pending") {
            return res.status(400).json({ message: "Can only update pending donations" });
        }

        // Mark as not received
        donation.status = "Not Received";
        await donation.save();

        // Remove from inventory if it was added (shouldn't be for Pending, but safety check)
        const inventory = await Inventory.findOne({
            campId: donation.campId,
            itemName: donation.itemName
        });

        if (inventory && inventory.quantity >= donation.quantity) {
            // Subtract the donation amount since it didn't arrive
            inventory.quantity -= donation.quantity;
            inventory.lastUpdated = new Date();
            await inventory.save();
            console.log(`📦 Removed from inventory: ${donation.quantity}${donation.unit} ${donation.itemName}`);
        }

        // Restore the remainingQty in CampRequest (donation didn't arrive)
        const request = await CampRequest.findOne({
            campId: donation.campId,
            itemName: donation.itemName,
            status: { $in: ["Pending", "open", "Open", "Fulfilled"] }
        });

        if (request) {
            // Add back to remaining since it didn't arrive
            request.remainingQty += donation.quantity;

            // Reopen request if it was fulfilled
            if (request.status === "Fulfilled") {
                request.status = "Pending";
            }

            await request.save();
        }

        console.log(`❌ Donation not received: ${donation.itemName} - ${donation.quantity}${donation.unit}`);

        res.json({
            message: "Donation marked as not received",
            remainingNeeded: request?.remainingQty || 0,
            newInventory: inventory?.quantity || 0
        });
    } catch (err) {
        console.error("Mark not received error:", err);
        res.status(500).json({ message: "Failed to mark as not received" });
    }
});

export default router;
