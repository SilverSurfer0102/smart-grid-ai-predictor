# 📖 Projekt-Glossar – Smart Grid AI Predictor

Dieser Glossar folgt dem Workflow des Projekts –
von der Einrichtung bis zur fertigen Cloud-Infrastruktur.

---

## 1️⃣ Lokale Entwicklungsumgebung

| Begriff | Bedeutung | Warum brauchen wir das? |
|---------|-----------|------------------------|
| `Homebrew` | Paketmanager für macOS – installiert Tools per Terminal | Ohne Homebrew müssten wir jedes Tool manuell von verschiedenen Webseiten herunterladen |
| `Git` | Versionskontrolle – speichert jeden Entwicklungsstand | Damit wir Änderungen nachverfolgen, rückgängig machen und auf GitHub teilen können |
| `Terraform` | Infrastructure as Code – beschreibt Cloud-Ressourcen als Textdatei | Damit unsere AWS-Infrastruktur reproduzierbar und versionierbar ist |
| `AWS CLI` | Kommandozeilen-Tool um mit AWS zu kommunizieren | Damit Terraform und wir direkt mit unserem AWS-Konto sprechen können |
| `VS Code` | Code-Editor mit integriertem Terminal | Komfortables Arbeiten – Dateien und Terminal an einem Ort |

---

## 2️⃣ Git – Versionskontrolle

### Git vs. GitHub – der Unterschied

| Begriff | Was ist es? | Wo es lebt | Braucht Internet | Analogie |
|---------|-------------|-----------|-----------------|---------|
| `Git` | Versionskontroll-Software – verfolgt alle Änderungen an deinen Dateien | Auf deinem Laptop | Nein | Dein Tagebuch auf dem Schreibtisch |
| `GitHub` | Cloud-Plattform die Git-Repositories hostet und visualisiert | In der Cloud | Ja | Kopie des Tagebuchs im Copyshop |
| `Repository (Repo)` | Ein Projektordner den Git überwacht – enthält alle Dateien und die komplette Änderungshistorie | Lokal und/oder GitHub | – | Das Tagebuch selbst |
| `git push` | Befehl der lokale Commits zu GitHub hochlädt | Verbindet beide | Ja | Kopie im Copyshop aktualisieren |
| `git pull` | Befehl der neueste Änderungen von GitHub herunterlädt | Verbindet beide | Ja | Neueste Kopie vom Copyshop holen |


### Git Workflow – Schritt für Schritt

| Schritt | Befehl | Wann benutzen? | Analogie |
|---------|--------|----------------|---------|
| 1 – Projekt starten | `git init` | Einmalig am Anfang | Tagebuch aufschlagen und beschriften |
| 2 – Überblick verschaffen | `git status` | Immer als erstes – bevor alles anderen | Blick in den Spiegel bevor man rausgeht |
| 3 – Dateien vormerken | `git add datei.md` | Nach jeder sinnvollen Änderung | Blatt in den Briefumschlag legen |
| 4 – Schnappschuss machen | `git commit -m "..."` | Nach git add – mit klarer Nachricht | Umschlag versiegeln und beschriften |
| 5 – Zu GitHub hochladen | `git push` | Nach dem Commit | Brief in den Briefkasten werfen |
| 6 – Fehler rückgängig | `git rm --cached datei.md` | Wenn eine Datei nicht getrackt werden soll | Blatt wieder aus dem Umschlag nehmen |



### Befehle
| Befehl | Bedeutung | Warum brauchen wir das? |
|--------|-----------|------------------------|
| `git init` | Neues Git-Projekt starten | Einmalig am Anfang – macht den Ordner zu einem Git-Projekt |
| `git add .` | Alle geänderten Dateien für Commit vorbereiten | Sagt Git: "Diese Dateien sollen im nächsten Snapshot sein" |
| `git commit -m "..."` | Änderungen mit Nachricht abspeichern | Erstellt einen Snapshot – wie ein Speicherpunkt in einem Videospiel |
| `git push` | Lokale Commits zu GitHub hochladen | Synchronisiert deinen lokalen Stand mit GitHub |
| `git status` | Zeigt welche Dateien geändert wurden | Übersicht bevor man committet – was hat sich geändert? |
| `git rm --cached` | Datei aus Git entfernen ohne sie zu löschen | Wenn eine Datei versehentlich getrackt wird die nicht in GitHub soll |

### Commit-Prefixe (Conventional Commits)
| Prefix | Bedeutung | Warum brauchen wir das? |
|--------|-----------|------------------------|
| `feat:` | Neue Funktion wurde hinzugefügt | Macht auf einen Blick klar was sich geändert hat |
| `fix:` | Fehler wurde behoben | Unterscheidet Bugfixes von neuen Features |
| `docs:` | Nur Dokumentation geändert | Kein Code geändert – nur Texte wie README oder Glossar |
| `refactor:` | Code aufgeräumt ohne neue Funktion | Code wurde verbessert aber das Verhalten ist gleich geblieben |
| `chore:` | Wartungsarbeit im Hintergrund | z.B. .gitignore aktualisieren oder generierte Dateien entfernen |

---

## 3️⃣ AWS – Grundbegriffe

| Begriff | Bedeutung | Warum brauchen wir das? |
|---------|-----------|------------------------|
| `Root Account` | Der Hauptaccount mit voller Kontrolle | Nur für die initiale Einrichtung – danach nie wieder benutzen |
| `IAM` | Identity and Access Management – verwaltet Zugriffsrechte | Damit nicht jeder alles darf – Sicherheitsprinzip |
| `IAM User` | Technischer Benutzer für ein Programm | Terraform braucht einen eigenen "Ausweis" um mit AWS zu sprechen |
| `IAM Role` | Temporärer Ausweis für AWS-Services | Lambda braucht Erlaubnis um S3 und SQS zu benutzen |
| `Trust Policy` | Definiert wer eine IAM Role benutzen darf | Nur Lambda darf diese Role annehmen – kein anderer Service |
| `Policy` | Liste von konkreten Erlaubnissen | z.B. "darf S3 schreiben aber nicht löschen" |
| `ARN` | Amazon Resource Name – weltweit eindeutige ID | Damit AWS-Services sich gegenseitig eindeutig referenzieren können |
| `Region` | Physischer Standort der Server | Wir nutzen Frankfurt – nah an uns und DSGVO-konform |
| `Free Tier` | Kostenloses AWS-Kontingent pro Monat | Unser Projekt bleibt damit nahezu kostenlos |

---

## 4️⃣ AWS – Services die wir benutzen

| Service | Bedeutung | Warum brauchen wir das? |
|---------|-----------|------------------------|
| `S3` | Dateispeicher in der Cloud | Speichert unsere Vorhersage-Ergebnisse als JSON-Dateien |
| `S3 Bucket` | Ein Container in S3 | Wie ein Ordner – alle unsere Prediction-Dateien landen hier |
| `SQS` | Nachrichtenwarteschlange | Puffert eingehende Sensordaten damit kein Datenverlust entsteht |
| `DLQ` | Dead Letter Queue – Auffangbecken für Fehler | Nachrichten die 3x fehlschlagen landen hier statt verloren zu gehen |
| `Lambda` | Serverlose Funktion | Verarbeitet Nachrichten aus SQS – läuft nur wenn Arbeit da ist |
| `CloudWatch` | Logging-Service von AWS | Speichert alle Ausgaben von Lambda – unverzichtbar für Debugging |
| `API Gateway` | Offizielle HTTP-Eingangstür für unser System | Damit externe Sensoren per HTTP Daten schicken können |
| `HTTP API` | Günstigste API Gateway Variante | Reicht für unser Projekt – einfacher als REST API |
| `Stage` | Eine Umgebung innerhalb der API | Wir nutzen "dev" – später könnte "prod" dazukommen |
| `Route` | Welcher URL-Pfad löst welche Aktion aus | POST /sensor → Nachricht in SQS schreiben |
| `CORS` | Erlaubt Anfragen von anderen Domains | Damit unser Frontend später die API aufrufen darf |


---

## 5️⃣ Terraform – Konzepte & Befehle

| Begriff | Bedeutung | Warum brauchen wir das? |
|---------|-----------|------------------------|
| `provider` | Plugin das mit AWS kommuniziert | Terraform spricht nicht direkt AWS – der Provider ist der Übersetzer |
| `resource` | Eine AWS-Ressource die Terraform erstellt | Jeder S3 Bucket, jede Queue ist eine resource in unserer .tf Datei |
| `variable` | Konfigurierbarer Wert | Damit wir z.B. die Region nur einmal ändern müssen |
| `output` | Wert der nach apply angezeigt wird | Zeigt uns z.B. den Bucket-Namen den wir später brauchen |
| `data` | Liest existierende Ressourcen – erstellt nichts | Wir lesen den Lambda-Code als ZIP ohne ihn neu zu bauen |
| `tfstate` | Zustandsdatei – was existiert gerade in AWS | Terraform merkt sich was bereits gebaut wurde |
| `.gitignore` | Dateien die Git nicht tracken soll | tfstate und .terraform dürfen nie in GitHub landen |
| `terraform init` | Provider und Plugins herunterladen | Einmalig am Anfang oder wenn neue Provider hinzukommen |
| `terraform plan` | Vorschau was gebaut werden würde | Sicherheitscheck bevor wir wirklich etwas in AWS verändern |
| `terraform apply` | Infrastruktur wirklich bauen | Baut alles was in den .tf Dateien steht in AWS |
| `terraform destroy` | Alle Ressourcen löschen | Aufräumen wenn wir nicht arbeiten – spart Kosten |

---

## 6️⃣ Lambda – Konzepte

| Begriff | Bedeutung | Warum brauchen wir das? |
|---------|-----------|------------------------|
| `lambda_handler` | Einstiegspunkt – hier startet Lambda | AWS ruft genau diese Funktion auf wenn eine SQS Nachricht kommt |
| `event` | Die eingehende Nachricht von SQS | Enthält die Sensordaten die wir verarbeiten sollen |
| `runtime` | Programmiersprache der Funktion | Wir nutzen Python 3.11 |
| `timeout` | Maximale Laufzeit in Sekunden | Nach 30 Sekunden bricht Lambda ab – verhindert Endlosschleifen |
| `environment variables` | Konfigurationswerte für Lambda | Bucket-Name wird so übergeben – kein hardcoding im Code |
| `source_code_hash` | Prüfsumme des Codes | Terraform erkennt ob sich der Code geändert hat und deployed neu |
| `batch_size` | Wie viele SQS Nachrichten auf einmal | Wir nehmen 1 – eine Nachricht pro Lambda-Aufruf |
| `invoke` | Lambda manuell aufrufen | Zum Testen ohne SQS – direkt per AWS CLI |
| `StatusCode 200` | Alles erfolgreich | HTTP-Standard: 200 = OK |
| `detect_trigger()` | Funktion die erkennt woher Lambda aufgerufen wurde | EventBridge und SQS liefern unterschiedliche JSON-Strukturen – Lambda muss unterscheiden |
| `event["source"]` | Feld im EventBridge-Event das den Absender angibt | `"aws.scheduler"` = kommt von EventBridge Scheduler |
| `event["Records"]` | Feld im SQS-Event das die Nachrichten enthält | Existiert nur bei SQS – fehlt bei EventBridge → guter Erkennungstest |
| `dual-trigger` | Lambda reagiert auf zwei verschiedene Auslöser | Pfad A: automatisch per EventBridge, Pfad B: on-demand per API/SQS |
| `build_hourly_forecast()` | Berechnet Vorhersage für alle Stunden | Liefert stündliche kW-Werte für 24h, 48h oder 72h Horizont |
| `forecast_days` | Wie viele Tage Open-Meteo zurückliefert | `1` = nur heute, `3` = 72h Vorhersage für Netzbetreiber |
| `UTC` | Koordinierte Weltzeit – Referenzzeitzone | Lambda läuft immer in UTC – Ortszeiten müssen manuell berechnet werden |
| `CEST / CET` | Mitteleuropäische Sommer-/Winterzeit | Nürnberg = UTC+2 im Sommer, UTC+1 im Winter – wichtig für Stunden-Index |
| `Performance Ratio` | Verhältnis von realer zu theoretischer Solarleistung | Berücksichtigt Wechselrichter-Verluste, Leitungen, Verschmutzung – Richtwert: 0.80 |
| `NOCT-Modell` | Temperaturkorrektur für Solarmodule | Panels verlieren ~0.4% Effizienz pro Grad über 25°C (Standard IEC 61215) |


---

## 7️⃣ Open-Meteo API

| Begriff | Bedeutung | Warum brauchen wir das? |
|---------|-----------|------------------------|
| `Open-Meteo` | Kostenlose Wetter-API | Liefert echte Wetterdaten ohne API-Key |
| `shortwave_radiation` | Kurzwellige Solarstrahlung in W/m² | Direkter Einflussfaktor auf Solarleistung |
| `hourly` | Stündliche Vorhersagewerte | Wir greifen auf die aktuelle Stunde zu |
| `Wirkungsgrad` | Wie viel % der Sonnenstrahlung wird zu Strom | Typische Solarmodule haben ~18% Wirkungsgrad |

---

## 8️⃣ EventBridge – Zeitgesteuerte Automatisierung

| Begriff | Bedeutung | Warum brauchen wir das? |
|---------|-----------|------------------------|
| `EventBridge` | AWS-Dienst für ereignisgesteuerte Architektur | Verbindet AWS-Services miteinander – reagiert auf Ereignisse oder Zeitpläne |
| `EventBridge Scheduler` | Zeitgesteuerter Auslöser für AWS-Services | Weckt Lambda automatisch alle 15 Minuten – kein manuelles Eingreifen nötig |
| `schedule_expression` | Definiert den Zeitplan als Formel | `rate(15 minutes)` = alle 15 Min., `cron(0 6 * * ? *)` = täglich um 6 Uhr |
| `rate()` | Einfacher Wiederholungs-Zeitplan | `rate(15 minutes)` – gleichmäßiger Takt ohne Datum/Uhrzeit-Logik |
| `cron()` | Präziser Zeitplan mit Datum und Uhrzeit | Aus der Unix-Welt – ermöglicht z.B. "jeden Montag um 8:00 Uhr" |
| `flexible_time_window` | Zeitfenster in dem EventBridge auslösen darf | `OFF` = genau zum Zeitpunkt, `FLEXIBLE` = irgendwann innerhalb eines Fensters |
| `Push-basierter Trigger` | EventBridge schickt aktiv ein Event zu Lambda | Lambda wartet passiv – wie eine Türklingel die jemand drückt |
| `Pull-basierter Trigger` | Lambda holt sich aktiv Nachrichten aus SQS | Lambda schaut regelmäßig in die Queue – wie ein Briefkasten der geleert wird |

---

## 🔟 Solarenergie – Fachbegriffe

| Begriff | Bedeutung | Warum brauchen wir das? |
|---------|-----------|------------------------|
| `kWp` | Kilowatt-Peak – Nennleistung einer Solaranlage | Gibt die maximale Leistung unter Idealbedingungen an (1000 W/m², 25°C) |
| `kW` | Kilowatt – aktuelle Leistung zu einem Zeitpunkt | Was die Anlage gerade produziert – schwankt mit Wetter und Uhrzeit |
| `kWh` | Kilowattstunde – produzierte Energie über Zeit | kW × Stunden = kWh, z.B. 1 kW × 4h = 4 kWh |
| `W/m²` | Watt pro Quadratmeter – Einheit der Sonnenstrahlung | Je höher, desto mehr Strom produziert das Panel |
| `Einspeiseprognose` | Vorhersage wie viel Strom ins Netz fließt | Netzbetreiber brauchen das um Reservekraftwerke zu steuern |
| `Wechselrichter` | Wandelt Gleichstrom (DC) der Panels in Wechselstrom (AC) | Verliert ~3-5% der Energie – Teil des Performance Ratio |
| `Systemwirkungsgrad` | Gesamteffizienz der Anlage inkl. aller Verluste | Modul-Wirkungsgrad × Performance Ratio = reale Ausbeute |
| `IEC 61215` | Internationale Norm für Solarmodule | Definiert Testbedingungen und Temperaturkoeffizienten – Grundlage unserer Formel |
| `IEC 61724` | Norm für Messung und Auswertung von Solaranlagen | Definiert den Performance Ratio – unser PR = 0.80 basiert darauf |
| `STC` | Standard Test Conditions – Referenzbedingungen | 1000 W/m² Strahlung, 25°C – unter diesen Bedingungen wird kWp gemessen |