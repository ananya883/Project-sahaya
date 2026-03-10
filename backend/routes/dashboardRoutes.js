import express from "express";
import CampRequest from "../models/CampRequest.js";
import MoneyDonation from "../models/MoneyDonation.js";

const router = express.Router();

router.get("/summary", async (req, res) => {
  const totalRequests = await CampRequest.countDocuments();
  const fulfilled = await CampRequest.countDocuments({
    status: { $in: ["fulfilled", "Fulfilled"] }
  });
  const pending = await CampRequest.countDocuments({
    status: { $in: ["Pending", "open", "Open", "pending", "active", "Active"] }
  });

  const money = await MoneyDonation.aggregate([
    { $group: { _id: null, total: { $sum: "$amount" } } }
  ]);

  res.json({
    inventory: {
      totalRequests,
      fulfilled,
      pending
    },
    totalMoneyDonated: money[0]?.total || 0
  });
});

export default router;
