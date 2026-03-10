import mongoose from "mongoose";

const userSchema = new mongoose.Schema(
  {
    // User Details
    Name: { type: String, required: true },
    gender: { type: String, required: true },
    dob: { type: String, required: true }, // Can also use Date type if preferred
    mobile: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    address: { type: String, required: true },
    houseNo: { type: String, required: true },

    // Roles (user, volunteer, donor)
    roles: {
      type: [String],
      enum: ["user", "volunteer", "donor"],
      default: ["user"]
    },

    // Volunteer Specific Details
    volunteerDetails: {
      skills: { type: [String], default: [] },
      trainingAttended: { type: Boolean, default: false },
      serviceLocation: { type: String },
      govtIdPath: { type: String },        // Path to uploaded ID
      certificatesPath: { type: String },  // Path to uploaded Certs
      certifications: { type: String },
      availability: { type: String },
      previousExperience: { type: [String], default: [] },
    },

    // Donor Specific Details
    donorDetails: {
      itemsOfInterest: { type: [String], default: [] },
      organizationName: { type: String },
      taxId: { type: String },
      donationType: { type: String, enum: ["funds", "goods", "both"] },
    },

    // Guardian Details (Optional for volunteers)
    guardianName: { type: String },
    guardianRelation: { type: String },
    guardianMobile: { type: String },
    guardianEmail: { type: String },
    guardianAddress: { type: String },

    isEmailVerified: { type: Boolean, default: false },
    emailOtp: { type: String },
    emailOtpExpires: { type: Date },

    otp: { type: String },
    otpExpires: { type: Date },
  },
  { timestamps: true } // Automatically adds createdAt and updatedAt
);

export default mongoose.model("User", userSchema);
