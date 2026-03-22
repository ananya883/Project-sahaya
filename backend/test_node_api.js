const locations = ['Meppadi', 'Vannappuram'];
fetch("http://127.0.0.1:5002/predict-alerts", {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify({ locations })
    })
.then(r => r.json())
.then(d => {
  console.log("From Flask:");
  console.log(JSON.stringify(d, null, 2));
  
  const allAlerts = d.alerts || [];
  const activeAlerts = allAlerts.filter(
    item => item.prediction && item.prediction.alert_level > 0
  );
  console.log("Active alerts:", JSON.stringify(activeAlerts, null, 2));
})
.catch(e => console.error(e));
