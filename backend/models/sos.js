import mongoose from "mongoose";

const sosSchema = new mongoose.Schema({
  emergency_type: { type: String, required: true },
  disaster_type: { type: String },
  latitude: { type: Number },
  longitude: { type: Number },
  timestamp: { type: Date, default: Date.now },
  image_url: { type: String },
});

export default mongoose.model("SOS", sosSchema);
