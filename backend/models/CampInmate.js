import mongoose from "mongoose";

const CampInmateSchema = new mongoose.Schema({
    campId: { type: String, required: true },
    name: { type: String, required: true },
    age: { type: Number, required: true },
    gender: { type: String, required: true, enum: ["Male", "Female", "Other"] },
    contactNumber: { type: String },
    aadharNumber: { type: String },
    address: { type: String },
    familyMembers: { type: Number, default: 1 },
    medicalConditions: { type: String },
    status: { type: String, default: "Active", enum: ["Active", "Relocated", "Left"] },
    registeredAt: { type: Date, default: Date.now }
});

export default mongoose.model("CampInmate", CampInmateSchema);
