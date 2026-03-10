import mongoose from "mongoose";

const donationSchema = new mongoose.Schema({
  donorName: String,
  campId: String,
  itemName: String,
  quantity: Number,
  status: {
    type: String,
    default: "Pending", // Pending | Received
  },
  donatedAt: {
    type: Date,
    default: Date.now,
  },
});

export default mongoose.models.Donation || mongoose.model("Donation", donationSchema);
