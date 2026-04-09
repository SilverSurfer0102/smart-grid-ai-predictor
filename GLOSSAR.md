# 📖 Projekt-Glossar – Smart Grid AI Predictor

---

## 🔀 Git – Conventional Commits
| Prefix | Bedeutung | Beispiel |
|--------|-----------|---------|
| `feat:` | Neue Funktion | `feat: add lambda function` |
| `fix:` | Bugfix | `fix: correct sqs timeout` |
| `docs:` | Dokumentation | `docs: update README` |
| `refactor:` | Code umstrukturiert (kein neues Feature) | `refactor: simplify main.tf` |
| `chore:` | Wartung, keine Logik-Änderung | `chore: update provider version` |


---

## ☁️ AWS – Begriffe
| Begriff | Bedeutung | Analogie |
|---------|-----------|---------|
| `ARN` | Amazon Resource Name – eindeutige ID jeder AWS-Ressource | Wie eine IBAN – weltweit einzigartig |
| `IAM` | Identity and Access Management – wer darf was? | Schlüsselverwaltung eines Gebäudes |
| `IAM User` | Technischer Benutzer für Programme | Hausmeister-Schlüssel |
| `IAM Role` | Temporäre Berechtigung für AWS-Services | Leihausweis für Lambda |
| `Root Account` | Der Hauptaccount – volle Kontrolle | Generalschlüssel |
| `Region` | Physischer Standort der Server | Rechenzentrum in Frankfurt |
| `S3` | Simple Storage Service – Dateispeicher | Aktenschrank in der Cloud |
| `S3 Bucket` | Container in S3 | Ein Ordner im Aktenschrank |
| `SQS` | Simple Queue Service – Nachrichtenwarteschlange | Förderband zwischen Services |
| `DLQ` | Dead Letter Queue – Auffangbecken für Fehler | Netz unter dem Trapez |
| `Lambda` | Serverlose Funktion – läuft nur wenn gebraucht | Arbeiter der nur kommt wenn Arbeit da ist |
| `Free Tier` | Kostenloses AWS-Kontingent pro Monat | Freiminuten beim Handyvertrag |

---

## 🏗️ Terraform – Begriffe
| Begriff | Bedeutung | Analogie |
|---------|-----------|---------|
| `provider` | Plugin das mit AWS "spricht" | Dolmetscher zwischen Terraform und AWS |
| `resource` | Eine AWS-Ressource die erstellt wird | Ein Bauteil im Schaltplan |
| `variable` | Konfigurierbarer Wert | Stellschraube |
| `output` | Wert der nach `apply` angezeigt wird | Zusammenfassung nach dem Hausbau |
| `terraform init` | Provider herunterladen | Werkzeuge ins Haus holen |
| `terraform plan` | Vorschau – was wird gebaut? | Bauplan prüfen vor dem Bauen |
| `terraform apply` | Infrastruktur bauen | Bagger anrollen lassen |
| `terraform destroy` | Alles löschen | Gebäude abreißen |
| `tfstate` | Zustandsdatei – was existiert aktuell? | Bestandsplan des Gebäudes |
| `.gitignore` | Dateien die Git ignoriert | "Diese Seiten nicht kopieren" |

---

## 🐍 Python – Kommt in Schritt 2
## ⚡ Lambda – Kommt in Schritt 2
## 🌤️ Open-Meteo API – Kommt in Schritt 2