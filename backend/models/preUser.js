import mongoose from "mongoose";

const PreUserSchema = new mongoose.Schema({
  email: { type: String, required: true, unique: true },
  otp: { type: String, required: false },
  otpExpiry: { type: Date, required:false},
  isVerified: { type: Boolean, default: false },
});

export default mongoose.model("PreUser", PreUserSchema);
