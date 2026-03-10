import mongoose from "mongoose";

const disasterSchema = new mongoose.Schema(
    {
        disasterId: {
            type: String,
            required: true,
            unique: true,
        },
        disasterName: {
            type: String,
            required: true,
        },
        location: {
            type: String,
            required: true,
        },
        latitude: {
            type: Number,
            required: false,
        },
        longitude: {
            type: Number,
            required: false,
        },
        dateOccurred: {
            type: Date,
            required: true,
        },
        disasterType: {
            type: String,
            required: true,
            enum: ["Flood", "Earthquake", "Fire", "Cyclone", "Landslide", "Tsunami", "Other"],
        },
        severity: {
            type: String,
            required: true,
            enum: ["Low", "Medium", "High", "Critical"],
            default: "Medium",
        },
        description: {
            type: String,
            default: "",
        },
        affectedPopulation: {
            type: Number,
            default: 0,
        },
        status: {
            type: String,
            enum: ["Active", "Resolved", "Monitoring"],
            default: "Active",
        },
    },
    { timestamps: true }
);

export default mongoose.models.Disaster || mongoose.model("Disaster", disasterSchema);
