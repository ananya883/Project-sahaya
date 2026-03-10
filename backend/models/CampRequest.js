import mongoose from "mongoose";

const campRequestSchema = new mongoose.Schema(
    {
        campId: {
            type: String,
            required: true,
        },
        campName: {
            type: String,
        },
        itemName: {
            type: String,
            required: true,
        },
        requiredQty: {
            type: Number,
            required: true,
        },
        remainingQty: {
            type: Number,
            required: true,
        },
        unit: String,
        category: String,
        priority: String,
        status: {
            type: String,
            default: "Pending",
            enum: ["Pending", "Fulfilled", "open", "Open"]
        },
    },
    { timestamps: true }
);

export default mongoose.models.CampRequest || mongoose.model("CampRequest", campRequestSchema);
