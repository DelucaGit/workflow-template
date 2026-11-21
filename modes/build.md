# Läge: build

För projekt där målet är att få något byggt. Claude planerar, skriver koden och sköter GitHub. Användaren godkänner, granskar och mergar.

Gäller utöver kärnreglerna i `WORKFLOW.md`. Ledtrådstrappan och lärloggen i `learn.md` gäller inte här.

## Roller

- **Claude planerar och skriver issues.** PRD, epics, stories och tasks kan Claude föreslå (gärna efter en diskussion), och skapar dem med `/issue`. Användaren går igenom varje rad och godkänner innan något flyttas till *Ready*.
- **Claude gör GitHub-arbetet:** issues, labels, sub-issues, Blocked by, board-status (även för story och epic), branches, commits och PR:er.
- **Claude skriver koden**, inklusive konfiguration och tester.
- **Användaren granskar och godkänner koden och mergar.** Claude mergar aldrig.

## Granskning

Claude skriver i PR:en vad som ändrats, hur det testades, vad som är osäkert och vilka filer utanför tasken som berörts. Användaren granskar diffen och godkänner eller ber om ändringar.

## Test först för kärnfunktioner

För varje kärnfunktion gäller i fast ordning:

1. Claude skriver testerna först och visar dem.
2. Användaren godkänner testerna. Ingen implementation skrivs före godkännandet.
3. Claude implementerar tills testerna passerar. Ett godkänt test ändras inte utan ett nytt godkännande.

**Kärnfunktion** = logik där ett fel skulle förstöra projektets huvudsyfte: affärslogik, datahantering, pengar, inloggning och behörighet, tid, externa tjänster, och varje buggfix (ett test som misslyckas och visar buggen skrivs först).

Inte kärnfunktion, och får hoppa över test-först: ren UI-layout, konfiguration och dokumentation.

Är Claude osäker på om något är en kärnfunktion, frågar Claude användaren i stället för att avgöra själv.
