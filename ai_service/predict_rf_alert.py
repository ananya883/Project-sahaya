import joblib
import numpy as np
import os
from datetime import datetime

class RFDisasterAlertSystem:
    """Production-ready Random Forest disaster alert predictor"""
    
    def __init__(self, model_path='rf_model.pkl', features_path='feature_names.pkl'):
        """Load trained models"""
        if not os.path.exists(model_path) or not os.path.exists(features_path):
            print(f"❌ Error: Could not find {model_path} or {features_path}.")
            print("Make sure you have run 'python train_rf_improved.py' first!")
            # We'll initialize with None so it doesn't crash on import, but will crash on predict
            self.model = None
            self.feature_names = None
        else:
            self.model = joblib.load(model_path)
            self.feature_names = joblib.load(features_path)
            print("✅ Random Forest model loaded successfully!")
    
    def predict_alert(self, rainfall, humidity, windspeed, temperature):
        """
        Predict disaster alert level from weather data using Random Forest
        
        Args:
            rainfall (float): Rainfall amount
            humidity (float): Humidity percentage (0-100)
            windspeed (float): Wind speed
            temperature (float): Temperature
            
        Returns:
            dict: Alert info with level, confidence, and reasoning
        """
        if self.model is None:
             return {"error": "Model not loaded. Please train the model first.", "status": "FAILED"}

        try:
            # Feature engineering (same as training)
            # Since this is a single real-time prediction point without history,
            # lag and diff features have to be 0 or derived from the current point
            rain_diff = 0  
            hum_rain = humidity * rainfall
            wind_rain = windspeed * rainfall
            rain_lag = 0  
            hum_lag = 0
            rain_avg_3 = rainfall  
            
            # Prepare feature array in the exact order expected by the model
            # Based on train_rf_improved.py:
            # ["Rainfall", "Humidity", "Windspeed", "Temperature", "RAIN_DIFF", "HUM_RAIN", "WIND_RAIN", "RAIN_LAG", "HUM_LAG", "RAIN_AVG_3"]
            features = np.array([[
                rainfall, humidity, windspeed, temperature,
                rain_diff, hum_rain, wind_rain,
                rain_lag, hum_lag, rain_avg_3
            ]])
            
            # Apply identical Feature Priority Weights as during training
            feature_weights = np.ones(10)
            weight_map = {
                0: 5.0,  # Rainfall
                1: 4.0,  # Humidity
                2: 3.0,  # Windspeed
                3: 0.5   # Temperature
            }
            for idx, w in weight_map.items():
                feature_weights[idx] = w
                
            features_weighted = features * feature_weights
            
            # Get RF prediction
            pred = self.model.predict(features_weighted)[0]
            # Get prediction probabilities for confidence score
            proba = self.model.predict_proba(features_weighted)[0]
            
            # Determine alert level
            alert_level = int(pred)
            confidence = round(float(proba[alert_level]) * 100, 1)
            
            alert_names = {0: "🟢 No Alert", 1: "🟠 MODERATE ALERT", 2: "🔴 HIGH ALERT"}
            alert_name = alert_names.get(alert_level, "Unknown")
            
            reasoning = [f"Random Forest classified as {alert_name}"]
            
            # Add weather context
            if rainfall > 50:
                reasoning.append(f"High rainfall: {rainfall:.1f}mm")
            if humidity > 80:
                reasoning.append(f"Very high humidity: {humidity:.1f}%")
            if windspeed > 30:
                reasoning.append(f"Strong wind: {windspeed:.1f} km/h")
            
            return {
                "timestamp": datetime.now().isoformat(),
                "alert_level": alert_level,
                "alert_name": alert_name,
                "confidence": confidence,
                "weather": {
                    "rainfall": rainfall,
                    "humidity": humidity,
                    "windspeed": windspeed,
                    "temperature": temperature
                },
                "reasoning": reasoning,
                "recommendation": self._get_recommendation(alert_level)
            }
            
        except Exception as e:
            return {
                "error": str(e),
                "timestamp": datetime.now().isoformat(),
                "status": "FAILED"
            }
    
    def _get_recommendation(self, alert_level):
        """Get action recommendation based on alert level"""
        recommendations = {
            0: "Monitor weather. No immediate action needed.",
            1: "Prepare evacuation plans. Enhanced monitoring recommended.",
            2: "EMERGENCY: Issue disaster alert. Begin immediate evacuation procedures."
        }
        return recommendations.get(alert_level, "Unknown alert level")
    
    def predict_batch(self, weather_data):
        """
        Predict alerts for multiple weather records
        """
        predictions = []
        for data in weather_data:
            prediction = self.predict_alert(
                data['rainfall'],
                data['humidity'],
                data['windspeed'],
                data['temperature']
            )
            predictions.append(prediction)
        return predictions


# ============================================================================
# EXAMPLE USAGE
# ============================================================================

if __name__ == "__main__":
    print("="*70)
    print("RANDOM FOREST DISASTER ALERT SYSTEM - PRODUCTION VERSION")
    print("="*70)
    
    # Initialize system
    alert_system = RFDisasterAlertSystem()
    
    if alert_system.model is None:
        print("Exiting due to missing models.")
        exit(1)

    print("\n" + "="*70)
    print("EXAMPLE 1: Normal Weather")
    print("="*70)
    result = alert_system.predict_alert(
        rainfall=10.5,
        humidity=65.0,
        windspeed=15.0,
        temperature=28.5
    )
    print(f"Alert Level: {result['alert_name']}")
    print(f"Confidence: {result['confidence']}%")
    print(f"Reasoning: {', '.join(result.get('reasoning', []))}")
    print(f"Recommendation: {result.get('recommendation', '')}")
    
    print("\n" + "="*70)
    print("EXAMPLE 2: High Rainfall")
    print("="*70)
    result = alert_system.predict_alert(
        rainfall=85.0,
        humidity=92.0,
        windspeed=35.0,
        temperature=24.0
    )
    print(f"Alert Level: {result['alert_name']}")
    print(f"Confidence: {result['confidence']}%")
    print(f"Reasoning: {', '.join(result.get('reasoning', []))}")
    print(f"Recommendation: {result.get('recommendation', '')}")
    
    print("\n" + "="*70)
    print("EXAMPLE 3: Extreme Weather (Anomaly)")
    print("="*70)
    result = alert_system.predict_alert(
        rainfall=120.0,
        humidity=98.0,
        windspeed=55.0,
        temperature=18.0
    )
    print(f"Alert Level: {result['alert_name']}")
    print(f"Confidence: {result['confidence']}%")
    print(f"Reasoning: {', '.join(result.get('reasoning', []))}")
    print(f"Recommendation: {result.get('recommendation', '')}")
    
    print("\n" + "="*70)
    print("SYSTEM READY FOR INTEGRATION")
    print("="*70)
    print("✅ Use RFDisasterAlertSystem class in your backend")
    print("✅ Call predict_alert() for single predictions")
    print("✅ Call predict_batch() for multiple locations")
