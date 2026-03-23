import pandas as pd
import os

folder_path = "data"
all_data = []

# -----------------------------
# STEP 1: READ & CLEAN DATA
# -----------------------------
for file in os.listdir(folder_path):
    if file.endswith(".csv"):
        file_path = os.path.join(folder_path, file)
        print("Reading:", file)

        df = pd.read_csv(file_path, skiprows=12)

        # Clean column names
        df.columns = df.columns.str.strip().str.upper()

        print("Columns:", df.columns)

        # Fix temperature column issue
        if "T2M_RANGE" not in df.columns and "T2M" in df.columns:
            print(f"🔁 Converting T2M → T2M_RANGE in {file}")
            df["T2M_RANGE"] = df["T2M"]

        # Ensure required columns exist
        required_cols = ["PRECTOTCORR", "WS2M", "QV2M", "T2M_RANGE"]

        for col in required_cols:
            if col not in df.columns:
                print(f"⚠️ {col} missing in {file}")
                df[col] = None

        # Add location
        df["LOCATION"] = file.replace(".csv", "")

        all_data.append(df)

# -----------------------------
# STEP 2: COMBINE DATA
# -----------------------------
combined_data = pd.concat(all_data, ignore_index=True)

# Remove extra temp column if exists
if "T2M" in combined_data.columns:
    combined_data.drop(columns=["T2M"], inplace=True)

# -----------------------------
# STEP 3: SORT DATA
# -----------------------------
combined_data = combined_data.sort_values(by=["LOCATION", "YEAR", "DOY"])

# -----------------------------
# STEP 4: CUMULATIVE RAINFALL
# -----------------------------
combined_data["RAIN_3DAY"] = combined_data.groupby("LOCATION")["PRECTOTCORR"]\
    .rolling(3).sum().reset_index(0, drop=True)

combined_data["RAIN_5DAY"] = combined_data.groupby("LOCATION")["PRECTOTCORR"]\
    .rolling(5).sum().reset_index(0, drop=True)

# Fill NaN values
combined_data["RAIN_3DAY"].fillna(0, inplace=True)
combined_data["RAIN_5DAY"].fillna(0, inplace=True)

# -----------------------------
# STEP 5: SCORING FUNCTIONS
# -----------------------------
def rain_score(r, r3, r5):
    if r5 > 100 or r3 > 80:
        return 2
    elif r3 > 40 or r > 30:
        return 1
    else:
        return 0

def humidity_score(h):
    if h > 15:
        return 2
    elif h > 10:
        return 1
    else:
        return 0

def wind_score(w):
    if w > 3:
        return 2
    elif w > 1:
        return 1
    else:
        return 0

def temp_score(t):
    if t > 10:
        return 2
    elif t > 5:
        return 1
    else:
        return 0

# -----------------------------
# STEP 6: APPLY SCORES
# -----------------------------
combined_data["RAIN_SCORE"] = combined_data.apply(
    lambda row: rain_score(row["PRECTOTCORR"], row["RAIN_3DAY"], row["RAIN_5DAY"]),
    axis=1
)

combined_data["HUM_SCORE"] = combined_data["QV2M"].apply(humidity_score)
combined_data["WIND_SCORE"] = combined_data["WS2M"].apply(wind_score)
combined_data["TEMP_SCORE"] = combined_data["T2M_RANGE"].apply(temp_score)

# -----------------------------
# STEP 7: TOTAL SCORE
# -----------------------------
combined_data["TOTAL_SCORE"] = (
    combined_data["RAIN_SCORE"] +
    combined_data["HUM_SCORE"] +
    combined_data["WIND_SCORE"] +
    combined_data["TEMP_SCORE"]
)

# -----------------------------
# STEP 8: FINAL ALERT
# -----------------------------
def final_alert(row):
    score = row["TOTAL_SCORE"]

    # Special landslide condition
    if row["RAIN_3DAY"] > 80 and row["QV2M"] > 15:
        return 2

    if score >= 6:
        return 2
    elif score >= 3:
        return 1
    else:
        return 0

combined_data["ALERT"] = combined_data.apply(final_alert, axis=1)

# -----------------------------
# STEP 9: SAVE FILE
# -----------------------------
output_file = "final_dataset_with_alert.csv"
combined_data.to_csv(output_file, index=False)

print("\n✅ Dataset with intelligent alerts created successfully!")
print(f"Saved as: {output_file}")