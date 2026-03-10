import mongoose from "mongoose";

const donationRecordSchema = new mongoose.Schema({
    campId: String,
    donorName: { type: String, default: "Anonymous Donor" },
    itemName: String,
    quantity: Number,
    unit: String, // e.g., kg, liters
    status: { type: String, default: "Pending" }, // Changed from "Received"
    donatedAt: { type: Date, default: Date.now },
    receivedAt: { type: Date }, // NEW: Track when physically received
});

export default mongoose.models.DonationRecord || mongoose.model("DonationRecord", donationRecordSchema);
