import express from "express";
import CampRequest from "../models/CampRequest.js";
import CampManager from "../models/CampManager.js";

const router = express.Router();

// Create inventory request
router.post("/request", async (req, res) => {
  try {
    const { campId, itemName, quantity, unit, category, priority } = req.body;

    const request = new CampRequest({
      campId,
      itemName,
      requiredQty: quantity,
      remainingQty: quantity,
      unit,
      category,
      priority,
      status: "Pending"
    });

    await request.save();
    res.json({ message: "Inventory request created" });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// View all open requests (donor dashboard)
router.get("/requests", async (req, res) => {
  try {
    const totalRequests = await CampRequest.countDocuments();
    const fulfilled = await CampRequest.countDocuments({
      status: { $in: ["fulfilled", "Fulfilled"] }
    });
    const pending = await CampRequest.countDocuments({
      status: { $in: ["Pending", "open", "Open", "pending", "active", "Active"] }
    });

    console.log(`📊 [BACKEND] Total requests in DB: ${totalRequests}`);
    console.log(`📊 [BACKEND] Fulfilled requests: ${fulfilled}`);
    console.log(`📊 [BACKEND] Pending/Open requests: ${pending}`);

    // Try to find pending/open requests first
    let requests = await CampRequest.find({
      status: { $in: ["Pending", "open", "Open", "pending", "active", "Active"] }
    }).sort({ createdAt: -1 });

    // fallback: if no pending requests, return ALL requests for debugging
    if (requests.length === 0) {
      console.log("⚠️ [BACKEND] No pending requests found. Returning all requests as fallback.");
      requests = await CampRequest.find().sort({ createdAt: -1 });
    }

    // Populate location from CampManager

    const enrichedRequests = await Promise.all(
      requests.map(async (req) => {
        const camp = await CampManager.findOne({ campId: req.campId });
        return {
          ...req.toObject(),
          location: camp?.location || "Unknown"
        };
      })
    );

    res.json(enrichedRequests);
  } catch (error) {
    console.error("Fetch requests error:", error);
    res.status(500).json({ message: "Failed to fetch requests" });
  }
});

// Get all valid camps for dropdown (donor dashboard)
router.get("/camps", async (req, res) => {
  try {
    const camps = await CampManager.find()
      .select("campId campName location")
      .sort({ campName: 1 });

    res.json(camps);
  } catch (error) {
    console.error("Fetch camps error:", error);
    res.status(500).json({ message: "Failed to fetch camps" });
  }
});

export default router;

