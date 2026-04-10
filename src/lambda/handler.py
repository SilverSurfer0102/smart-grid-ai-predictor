import json
import boto3
import os
import urllib.request
from datetime import datetime, timezone

# S3 Client – unser Werkzeug um mit S3 zu sprechen
s3 = boto3.client("s3")

# Den Bucket-Namen aus der Umgebungsvariable lesen
# (Terraform setzt das automatisch – kommt gleich)
BUCKET_NAME = os.environ["BUCKET_NAME"] 


def fetch_weather_data():
    """
    Zieht echte Wetterdaten von der Open-Meteo API.
    Wir holen Solardaten für München (Nähe zu Ansbach).
    Keine API-Key nötig – komplett kostenlos!
    """
    url = (
        "https://api.open-meteo.com/v1/forecast"
        "?latitude=49.45&longitude=11.08"
        "&hourly=temperature_2m,windspeed_10m,shortwave_radiation"
        "&forecast_days=1"
        "&timezone=Europe/Berlin"
    )

    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read().decode())

    # Nur die aktuelle Stunde extrahieren
    current_hour = datetime.now().hour
    return {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "location": "Nürnberrg (49.45N, 11.08E)",
        "temperature_c": data["hourly"]["temperature_2m"][current_hour],
        "windspeed_kmh": data["hourly"]["windspeed_10m"][current_hour],
        "solar_radiation_wm2": data["hourly"]["shortwave_radiation"][current_hour],
    }


def predict_solar_output(weather):
    """
    Einfache regelbasierte KI-Vorhersage.
    Schritt 3 wird das durch ein echtes ML-Modell ersetzen.

    Formel: Solarleistung hängt von Strahlung und Temperatur ab.
    Panels verlieren ~0.4% Effizienz pro Grad über 25°C.
    """
    base_output = weather["solar_radiation_wm2"] * 0.18  # 18% Wirkungsgrad

    # Temperaturkorrektur
    temp_correction = 1 - (max(0, weather["temperature_c"] - 25) * 0.004)
    predicted_kw = base_output * temp_correction

    # Windkorrektur (hoher Wind kühlt Panels – leicht positiv)
    wind_bonus = min(0.05, weather["windspeed_kmh"] * 0.001)
    predicted_kw = predicted_kw * (1 + wind_bonus)

    return round(predicted_kw, 2)


def lambda_handler(event, context):
    """
    Hauptfunktion – wird von SQS getriggert.
    event enthält die SQS Nachrichten.
    """
    print(f"Verarbeite {len(event['Records'])} Nachrichten...")

    results = []

    for record in event["Records"]:
        # SQS Nachricht lesen
        body = json.loads(record["body"])
        print(f"Nachricht erhalten: {body}")

        # Echte Wetterdaten holen
        weather = fetch_weather_data()

        # KI-Vorhersage berechnen
        predicted_output = predict_solar_output(weather)

        # Ergebnis zusammenbauen
        result = {
            "input_message": body,
            "weather_data": weather,
            "predicted_solar_output_kw": predicted_output,
            "processed_at": datetime.now(timezone.utc).isoformat(),
        }

        # In S3 speichern
        filename = f"predictions/{datetime.now().strftime('%Y/%m/%d')}/{datetime.now().strftime('%H-%M-%S')}.json"

        s3.put_object(
            Bucket=BUCKET_NAME,
            Key=filename,
            Body=json.dumps(result, indent=2),
            ContentType="application/json",
        )

        print(f"Ergebnis gespeichert: s3://{BUCKET_NAME}/{filename}")
        results.append(result)

    return {
        "statusCode": 200,
        "body": json.dumps({
            "processed": len(results),
            "results": results
        })
    }