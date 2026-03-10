import mongoose from "mongoose";

const inventorySchema = new mongoose.Schema({
  campId: String,
  itemName: String,
  quantity: Number,
  lastUpdated: {
    type: Date,
    default: Date.now,
  },
});

export default mongoose.models.Inventory || mongoose.model("Inventory", inventorySchema);
