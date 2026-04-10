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

---

## 7️⃣ Open-Meteo API

| Begriff | Bedeutung | Warum brauchen wir das? |
|---------|-----------|------------------------|
| `Open-Meteo` | Kostenlose Wetter-API | Liefert echte Wetterdaten ohne API-Key |
| `shortwave_radiation` | Kurzwellige Solarstrahlung in W/m² | Direkter Einflussfaktor auf Solarleistung |
| `hourly` | Stündliche Vorhersagewerte | Wir greifen auf die aktuelle Stunde zu |
| `Wirkungsgrad` | Wie viel % der Sonnenstrahlung wird zu Strom | Typische Solarmodule haben ~18% Wirkungsgrad |