import json
import boto3
import os
import urllib.request
from datetime import datetime, timezone, timedelta

s3 = boto3.client("s3")
BUCKET_NAME = os.environ["BUCKET_NAME"]

# ── Konfiguration ─────────────────────────────────────────────
DEFAULT_LAT  = 49.45
DEFAULT_LON  = 11.08
DEFAULT_CITY = "Nuremberg"
PERFORMANCE_RATIO = 0.80  # Systemwirkungsgrad (IEC 61724): Wechselrichter, Leitungen, Verschmutzung


# ── Trigger-Erkennung ─────────────────────────────────────────
def detect_trigger(event: dict) -> str:
    """
    Erkennt woher Lambda aufgerufen wurde.
    Wie ein Türsteher der schaut von welchem Eingang jemand kommt.

    Rückgabe: "eventbridge" | "sqs" | "unknown"
    """
    if "source" in event and "scheduler" in event.get("source", ""):
        return "eventbridge"
    if "Records" in event and len(event["Records"]) > 0:
        if event["Records"][0].get("eventSource") == "aws:sqs":
            return "sqs"
    # EventBridge Scheduler hat detail-type
    if "detail-type" in event:
        return "eventbridge"
    return "unknown"


# ── Wetterdaten holen ─────────────────────────────────────────
def fetch_weather_forecast(lat: float, lon: float, days: int = 3) -> dict:
    """
    Holt stündliche Wetterdaten von Open-Meteo.
    days=3 -> Vorhersage fuer heute, morgen, übermorgen.

    Wichtig: Wir fordern timezone=Europe/Berlin an damit
    die Stunden-Indizes mit der Ortszeit übereinstimmen.
    """
    url = (
        f"https://api.open-meteo.com/v1/forecast"
        f"?latitude={lat}&longitude={lon}"
        f"&hourly=temperature_2m,windspeed_10m,shortwave_radiation"
        f"&forecast_days={days}"
        f"&timezone=Europe%2FBerlin"
    )

    with urllib.request.urlopen(url, timeout=10) as response:
        data = json.loads(response.read().decode())

    hours      = data["hourly"]["time"]
    temps      = data["hourly"]["temperature_2m"]
    winds      = data["hourly"]["windspeed_10m"]
    radiations = data["hourly"]["shortwave_radiation"]

    # Aktuelle Stunde in Ortszeit (Berlin) finden
    # Lambda läuft in UTC – wir berechnen Berliner Zeit manuell
    utc_now     = datetime.now(timezone.utc)
    # Einfache Näherung: CET=UTC+1, CEST=UTC+2
    # Für Produktion: pytz oder zoneinfo nutzen
    berlin_hour = (utc_now.hour + 1) % 24  # Minimum UTC+1

    # Aktuellen Datumsstempel im Berlin-Format finden
    berlin_date = (utc_now + timedelta(hours=1)).strftime("%Y-%m-%dT%H:00")
    current_idx = next(
        (i for i, t in enumerate(hours) if t == berlin_date),
        berlin_hour  # Fallback falls kein exakter Match
    )

    return {
        "location":     {"city": DEFAULT_CITY, "lat": lat, "lon": lon},
        "fetched_at":   utc_now.isoformat(),
        "current_hour": {
            "time":             hours[current_idx],
            "temperature_c":    temps[current_idx],
            "windspeed_kmh":    winds[current_idx],
            "solar_radiation":  radiations[current_idx],
        },
        # Alle Stunden für die Vorhersage mitgeben
        "hourly": {
            "time":        hours,
            "temperature": temps,
            "windspeed":   winds,
            "radiation":   radiations,
        }
    }


# ── Solarleistung berechnen ───────────────────────────────────
def predict_solar_output(temperature_c: float,
                          radiation_wm2: float,
                          windspeed_kmh: float,
                          panel_kwp: float = 10.0) -> float:
    """
    Regelbasierte Solarleistungsvorhersage.

    Formel basiert auf Standard-Derating-Faktoren (IEC 61215):
    - Wirkungsgrad: 18% (typisch monokristallin)
    - Temperaturkoeffizient: -0.4%/°C über 25°C (NOCT-Modell)
    - Windkühlung: bis +5% bei hohem Wind

    panel_kwp: Nennleistung der Anlage in kWp (Standard: 10 kWp)
    """
    if radiation_wm2 <= 0:
        return 0.0  # Nachts keine Leistung

    # Basisleistung: Strahlung * Wirkungsgrad
    base_output_kw = (radiation_wm2 / 1000) * panel_kwp * 0.18

    # Temperaturkorrektur (STC-Referenz: 25°C)
    temp_derating = 1 - (max(0.0, temperature_c - 25) * 0.004)

    # Windkühlung (hoher Wind kühlt Panel → leicht mehr Leistung)
    wind_bonus = 1 + min(0.05, windspeed_kmh * 0.001)

    return round(base_output_kw * temp_derating * wind_bonus * PERFORMANCE_RATIO, 3)


def build_hourly_forecast(weather: dict, panel_kwp: float = 10.0) -> list:
    """
    Berechnet stündliche Vorhersage für alle verfügbaren Stunden.
    Das ist der Mehrwert gegenüber nur der aktuellen Stunde.
    """
    hourly = weather["hourly"]
    forecast = []

    for i, time_str in enumerate(hourly["time"]):
        kw = predict_solar_output(
            temperature_c  = hourly["temperature"][i],
            radiation_wm2  = hourly["radiation"][i],
            windspeed_kmh  = hourly["windspeed"][i],
            panel_kwp      = panel_kwp,
        )
        forecast.append({"time": time_str, "predicted_kw": kw})

    return forecast


# ── S3 speichern ──────────────────────────────────────────────
def save_to_s3(result: dict, prefix: str = "predictions") -> str:
    now      = datetime.now(timezone.utc)
    filename = f"{prefix}/{now.strftime('%Y/%m/%d/%H-%M-%S')}.json"

    s3.put_object(
        Bucket      = BUCKET_NAME,
        Key         = filename,
        Body        = json.dumps(result, indent=2, ensure_ascii=False),
        ContentType = "application/json",
    )
    return filename


# ── Haupt-Handler ─────────────────────────────────────────────
def lambda_handler(event, context):
    print(f"Event empfangen: {json.dumps(event)[:300]}")

    trigger = detect_trigger(event)
    print(f"Trigger erkannt: {trigger}")

    # ── Pfad A: EventBridge → automatische 72h-Vorhersage ──
    if trigger in ("eventbridge", "unknown"):
        weather  = fetch_weather_forecast(DEFAULT_LAT, DEFAULT_LON, days=3)
        forecast = build_hourly_forecast(weather)

        result = {
            "trigger":          "eventbridge_scheduled",
            "forecast_horizon": "72h",
            "weather_source":   "open-meteo",
            "location":         weather["location"],
            "fetched_at":       weather["fetched_at"],
            "current_conditions": weather["current_hour"],
            "hourly_forecast":  forecast,
        }

        filename = save_to_s3(result, prefix="predictions/scheduled")
        print(f"Automatische Vorhersage gespeichert: {filename}")

        return {"statusCode": 200, "body": json.dumps({"file": filename})}

    # ── Pfad B: SQS/API Gateway → On-Demand Anfrage ──
    results = []
    for record in event["Records"]:
        body = json.loads(record["body"])
        print(f"On-Demand Anfrage: {body}")

        # Standort aus Anfrage oder Default
        lat  = body.get("lat",  DEFAULT_LAT)
        lon  = body.get("lon",  DEFAULT_LON)
        city = body.get("city", DEFAULT_CITY)

        weather  = fetch_weather_forecast(lat, lon, days=1)
        forecast = build_hourly_forecast(weather)

        result = {
            "trigger":          "api_on_demand",
            "requested_by":     body.get("sensor_id", "unknown"),
            "location":         {"city": city, "lat": lat, "lon": lon},
            "fetched_at":       weather["fetched_at"],
            "current_conditions": weather["current_hour"],
            "hourly_forecast":  forecast,
        }

        filename = save_to_s3(result, prefix="predictions/on-demand")
        print(f"On-Demand Vorhersage gespeichert: {filename}")
        results.append({"file": filename})

    return {"statusCode": 200, "body": json.dumps({"processed": len(results), "results": results})}