import mongoose from "mongoose";

const MoneyDonationSchema = new mongoose.Schema({
  donorId: String,
  campId: String,
  amount: Number,
  paymentStatus: String,
  donatedAt: { type: Date, default: Date.now }
});

export default mongoose.models.MoneyDonation || mongoose.model("MoneyDonation", MoneyDonationSchema);
