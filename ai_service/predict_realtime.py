import os
from pathlib import Path
from dotenv import load_dotenv
import requests
import time
from predict_rf_alert import RFDisasterAlertSystem

# -----------------------------
# STEP 1: Load Environment Variables
# -----------------------------
# Find the .env file relative to this script's location (/backend/.env)
base_dir = Path(__file__).resolve().parent.parent
env_path = base_dir / "backend" / ".env"

if not env_path.exists():
    print(f"❌ ERROR: .env file not found at {env_path}")
    exit(1)

load_dotenv(dotenv_path=env_path)
API_KEY = os.getenv("OPENWEATHER_API_KEY")

if not API_KEY:
    print("❌ ERROR: OPENWEATHER_API_KEY not found in .env file.")
    exit(1)

# -----------------------------
# STEP 2: Configure Target Locations
# -----------------------------
# Coordinates for requested locations
LOCATIONS = {
    "Vannappuram": (9.90, 76.80),
    "Adimali": (10.02, 76.97),
    "Cheruthoni": (9.85, 76.98),
    "Kokkayar": (9.57, 76.85),
    "Sulthan Bathery": (11.67, 76.27),
    "Meppadi": (11.55, 76.13),
    "Kalpetta": (11.61, 76.08),
    "Munnar": (10.09, 77.06),
    "Vythiri": (11.55, 76.04)
}

# -----------------------------
# STEP 3: Fetch Real-Time Weather
# -----------------------------
def get_current_weather(lat, lon, name):
    url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={API_KEY}&units=metric"
    
    try:
        response = requests.get(url, timeout=10)
        data = response.json()
        
        if response.status_code != 200 or "main" not in data:
            print(f"⚠️ Error fetching data for {name}: {data.get('message', 'Unknown error')}")
            return None
            
        # Extract required features
        weather = {
            "location": name,
            "temperature": data["main"]["temp"],
            "humidity": data["main"]["humidity"],
            "windspeed": data["wind"]["speed"],
            # OpenWeather provides rain volume for last 1 hour, default 0 if no rain
            "rainfall": data.get("rain", {}).get("1h", 0)
        }
        return weather
    except requests.exceptions.RequestException as e:
        print(f"⚠️ Network error fetching data for {name}: {e}")
        return None

# -----------------------------
# STEP 4: Main Execution
# -----------------------------
if __name__ == "__main__":
    print("="*60)
    print("🌍 REAL-TIME CLIMATE DISASTER MONITORING SYSTEM")
    print("="*60)
    
    # Initialize the ML Model
    alert_system = RFDisasterAlertSystem()
    if alert_system.model is None:
        print("❌ Exiting: ML Models not found. Train the model first.")
        exit(1)
            
    print(f"✅ Scanning {len(LOCATIONS)} high-risk regions...")
    
    predictions_results = []
    
    for name, (lat, lon) in LOCATIONS.items():
        print(f"\n📡 Fetching live data for {name}...")
        weather_data = get_current_weather(lat, lon, name)
        
        if weather_data:
            print(f"   [Data] Temp: {weather_data['temperature']}°C | Hum: {weather_data['humidity']}% | Wind: {weather_data['windspeed']}km/h | Rain: {weather_data['rainfall']}mm")
            
            # Use Random Forest to predict Alert Risk
            result = alert_system.predict_alert(
                rainfall=weather_data['rainfall'],
                humidity=weather_data['humidity'],
                windspeed=weather_data['windspeed'],
                temperature=weather_data['temperature']
            )
            
            if result.get("status") == "FAILED":
                print(f"   ❌ ML Prediction failed: {result.get('error')}")
                continue
                
            alert_level = result['alert_level']
            alert_name = result['alert_name']
            conf = result['confidence']
            reasoning = result.get('reasoning', [])
            
            print(f"   🚨 Predict: {alert_name} (Confidence: {conf}%)")
            for r in reasoning[1:]:
                print(f"      - {r}")
                
            predictions_results.append({
                "location": name,
                "alert_level": alert_level,
                "data": weather_data,
                "prediction": result
            })
            
        # Respect API rate limits (e.g., free tier 60 calls/min)
        time.sleep(1)

    print("\n" + "="*60)
    print("📊 SUMMARY REPORT")
    print("="*60)
    
    # Sort with highest risk first
    predictions_results.sort(key=lambda x: x['alert_level'], reverse=True)
    
    for r in predictions_results:
        print(f"{r['prediction']['alert_name']:<18} | {r['location']}")
           
