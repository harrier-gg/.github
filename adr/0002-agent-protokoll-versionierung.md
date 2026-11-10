# 0002: Versionierung des Agent-Protokolls

- **Status:** Angenommen
- **Datum:** 2026-11-10

## Kontext
Agents laufen auf den Rechnern der Nutzer und werden einzeln aktualisiert. Panel und Agents haben daher zeitweise verschiedene Versionen. Ein Panel-Update darf laufende Agents nicht sofort unbrauchbar machen.

## Entscheidung
- Der Agent verbindet sich immer ausgehend per WebSocket mit dem Gateway (`/agent/ws`).
- Erste Nachricht ist `hello` mit `protocol` (ganze Zahl). Das Gateway antwortet mit `welcome` oder `reject` (inkl. `minProtocol`/`maxProtocol` und Begründung) und schließt dann die Verbindung.
- Die Protokollversion steigt nur bei inkompatiblen Änderungen. Neue optionale Felder und neue Nachrichtentypen, die die Gegenseite ignorieren darf, erhöhen sie nicht.
- Das Gateway unterstützt immer die aktuelle und die vorherige Version (`PROTOCOL` in `apps/gateway/src/agents/handshake.ts`).
- Ein abgelehnter Agent beendet sich (Exit-Code 2), statt endlos neu zu verbinden.

## Konsequenzen
- Ein Panel-Update mit neuer Protokollversion lässt Agents der Vorversion weiterlaufen; Nutzer haben ein Release Zeit zum Aktualisieren.
- Das Gateway muss für die Vorversion Kompatibilitätscode behalten und ihn ein Release später entfernen.
