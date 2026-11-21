# WORKFLOW.md – Så jobbar vi i GitHub

Reglerna gäller för varje projekt. Den enda källan till sanning är repot `workflow-template`. Ändras en regel ändras den här, och den gäller direkt i alla projekt.

Befintligt arbete lämnas som det är. Reglerna gäller för allt nytt arbete.

---

## 0. Läge

Varje projekt har ett läge som styr vem som skriver koden och vem som gör GitHub-arbetet. Läget sätts med en rad i projektets egen `CLAUDE.md`:

```
Workflow mode: learn
```

eller `Workflow mode: build`. Saknas raden gäller **build**. Ett projekt är bara ett learn-projekt när användaren har sagt det.

| Läge | Kod | GitHub-arbetet | Claude är |
|---|---|---|---|
| `learn` | Användaren | Användaren | Mentor och granskare |
| `build` | Claude (test först för kärnfunktioner) | Claude | Byggare. Användaren godkänner, granskar och mergar |

Reglerna för varje läge finns i `modes/learn.md` och `modes/build.md`. Reglerna i resten av den här filen gäller i båda lägena. Hänvisar en regel till "läget" gäller det som står i lägets fil.

I båda lägena **mergar Claude aldrig**.

## 1. Hierarki

PRD → Epic → Story → Task. Varje nivå är en GitHub-issue, kopplad till nivån ovanför med GitHubs sub-issues. Typen sätts med label (`type:prd`, `type:epic`, `type:story`, `type:task`), inte med GitHubs issue types.

| Nivå | Vad det är | Språk |
|---|---|---|
| PRD | Målet. En per version (se regel 10) | Tekniskt tillåtet |
| Epic | En stor leverans | Vanligt språk som alla förstår |
| Story | En vertikal skiva som en användare kan prova | Vanligt språk som alla förstår |
| Task | Ett konkret arbetspaket som en person hinner på en halv dag. En task = en branch = en PR | Tekniskt |

Bara en task ger kod och en PR.

**Spike:** en task med "Spike" i titeln är ett tidsbegränsat experiment (max en halv dag) för att svara på en fråga, till exempel "kan Hostingers API koppla sajt till repo?". Resultatet är ett svar skrivet i issuen, inte kod i `main`. Koden kastas eller sparas i en egen branch.

Undantag: en epic i *Backlog* får sakna PRD och milestone tills den planeras in i en version. Innan den flyttas till *Ready* ska den kopplas till en PRD.

**Språk:** allt som skrivs i GitHub (issues, PR:er, commits, mallar, labels) skrivs på engelska. `WORKFLOW.md` är på svenska.

## 2. Beroenden och filer

- Blockering sätts med GitHubs inbyggda **Blocked by / Blocking**. Det är den enda källan, ingen lista i issue-texten.
- En issue får inte flyttas till *In progress* så länge något den är blockerad av är öppet. Blockerade issues har `status:blocked`.
- Varje task har en filsektion med tre rader: `Files to change`, `Files to create`, `Files read-only`.
- Två öppna tasks som ändrar samma fil blockerar varandra, om de inte tydligt rör olika delar av filen. De körs aldrig parallellt.

## 3. Labels

Exakt 11 labels, samma i alla repon. Inga egna labels per projekt. Listan finns i `labels.json`.

- Typ (exakt en per issue): `type:prd`, `type:epic`, `type:story`, `type:task`, `type:bug`
- Prioritet (stories och buggar): `priority:high`, `priority:medium`, `priority:low`
- Storlek (bara tasks): `size:s` = under ca 2 timmar, `size:m` = upp till en halv dag. En task som är större än m delas upp.
- Status: `status:blocked`

Behövs en ny label ändras den globala listan här, aldrig lokalt i ett projekt.

## 4. Board

Ett GitHub Project per repo, med **Table-vy och nästlade sub-issues** (PRD, epic, story, task i ett träd). Varje rad visar Status, Typ, Storlek, Prioritet och Blocked by. Om trädet visar sig begränsat i GitHub lägger vi till en Board-vy som komplement.

Status har fem värden:

1. **Backlog** – idéer och oplanerade issues.
2. **Ready** – klar att starta: acceptanskriterier och filsektion finns, storlek är satt, alla blockerare är stängda (*Definition of Ready*).
3. **In progress** – någon arbetar på den, med en branch.
4. **In review** – PR är öppen.
5. **Done** – PR mergad, issue stängd.

Stories och epics ska följa med: *In progress* när någon task under dem är det, *Done* när alla tasks under dem är stängda. GitHub gör inte det av sig själv, så status på story och epic uppdateras för hand när en task flyttas. Vem som gör det styrs av läget (regel 0).

Gräns för pågående arbete: max en task *In progress* per session eller agent, och aldrig två samtidiga tasks som ändrar samma fil.

## 5. Scrum

- **Sprint** = fältet *Iteration* i GitHub Projects. Sprintar på 1 vecka (måndag till söndag).
- **Sprintplanering**: vi väljer hela stories, aldrig enstaka lager från flera stories. En story tas in bara om alla dess tasks är *Ready* eller kan bli det under sprinten.
- **Sprintmål**: en mening på vanligt språk om vad som ska fungera vid veckans slut.
- **Sprintavslut**: en kommentar på PRD-issuen med vad som blev klart, vad som flyttades, vad vi lär oss, och användarens egen reflektion: *vad lärde jag mig, och vad var svårast?* Ofärdiga stories går tillbaka till *Backlog* eller nästa sprint, aldrig i halvfärdigt skick.
- Ingen daily.

## 6. Mallar

En issue-mall per typ. Fet text är obligatoriskt. Titelprefix: `[PRD]`, `[Epic]`, `[Story]`, `[Task]`, `[Bug]`.

- **PRD**: **Goal**, **Who it is for**, **In scope**, **Out of scope**, **How we measure success**. Skrivs som en sammanfattning av diskussionen mellan användaren och Claude.
- **Epic** (vanligt språk): **What is delivered**, **Why it is needed**, **How we know it is done**.
- **Story** (vanligt språk): **As a [who] I want [what] so that [why]** och **Acceptance criteria** som en person kan se eller prova, utan teknik.
- **Task**: **What to do**, **Learning goal** (vad användaren ska förstå efteråt), **Where to look** (länkar till dokumentation, inte lösningen), **Files to change / create / read-only**, **Acceptance criteria** som går att testa, **Size**, **Out of scope**.
- **Bug**: **What happened**, **What should happen**, **Steps to reproduce**, **Environment**.

## 7. Branch, PR och merge

- Branch: `task/<issue-nummer>-<kort-namn>`, till exempel `task/42-login-form`. Buggar: `bug/<nummer>-<namn>`. Alla utgår från `main`.
- Commits börjar med issue-numret: `[#42] Add login form`.
- En PR per task. Titel `[Task] ...`, och beskrivningen innehåller `Closes #<nummer>`, vad som ändrades, hur det testades och vilka filer som berördes. En fil utanför tasken ska förklaras.
- Merge: squash merge, branchen raderas efteråt.
- Ingen direkt push till `main`: allt går via PR. Det är en överenskommelse och inte en teknisk spärr (GitHub kräver Pro för skydd i privata repon). En PR mergas först när tasken inte har öppna blockerare.

## 8. Vertikalt arbete

- Varje story är en komplett vertikal skiva, från knapp till databas.
- Tasks i en story delas per lager i fast ordning, där varje task blockeras av den före: **1. backend/logik → 2. API → 3. frontend → 4. end-to-end-test** (hela kedjan, från knapptryck till backend).
- Storyn är klar först när end-to-end-testet är grönt.
- En story i taget. Vi börjar inte på nästa förrän den förra är klar.
- Första storyn i varje epic är den tunnaste möjliga skivan som ändå går hela vägen.
- Ingen task bygger ett helt lager i förväg (till exempel "hela backend för epiken"). Horisontellt arbete är förbjudet.
- **Liten story:** om en storys hela skiva ryms i en task med `size:m` får den vara en enda task i stället för fyra lager-tasks. Den är fortfarande vertikal och kräver ett grönt end-to-end-test.

## 9. Nytt arbete och buggar

- Allt nytt arbete börjar som en issue i *Backlog*. Ingen bygger något som inte först blivit en issue.
- En bugg som hindrar end-to-end-testet i den pågående storyn blir en ny task under den storyn och fixas innan storyn blir *Done*.
- Andra buggar får `type:bug` och prioritet, och väntar till nästa sprintplanering.
- En bugg med `priority:high` som förstör något som redan fungerar får avbryta sprinten. Den görs direkt som egen task och nämns i sprintavslutet.
- Nya önskemål mitt i en sprint blir en ny story i *Backlog*. Sprintens stories ändras inte.
- Epics, stories och tasks planeras enligt läget (regel 0). I båda lägena godkänner användaren dem innan något flyttas till *Ready*.

## 10. Versioner och releaser

- Varje version är en **milestone** (till exempel `v2.0`) med en egen **PRD-issue**. Projekt utan versioner får en enda milestone, `v1.0`.
- Release: när alla stories i milestonen är *Done* skapas en tagg (`v2.0.0`) och en GitHub Release med en sammanfattning på vanligt språk från de stängda stories.
- Buggfixar efter release hamnar i en ny milestone: `v2.0.1`, eller `v2.1` om de är större.

## 11. Definition of Done och granskning

- En task är färdig när alla acceptanskriterier är uppfyllda, testerna passerar, inga filer utanför filsektionen ändrats utan förklaring, och PR:en är mergad.
- **Granskning** görs enligt läget (regel 0): i `learn` granskar Claude användarens kod i en fast ordning, i `build` granskar användaren Claudes kod.
- **Användaren godkänner och mergar. Claude mergar aldrig.**
- Användaren provar varje story som en användare, godkänner den när end-to-end-testet är grönt, och först då stängs den.

## 12. Stanna och fråga vid avvikelser

Så fort något avviker från det som förväntades (felmeddelande, test som fallerar, kommando som inte fungerar, verktyg eller fil som saknas, resultat som inte stämmer med tasken) gäller:

1. Stanna och gör ingenting mer på området.
2. Rapportera: **vad** som gick fel, **varför** (säg om det inte är känt), vilka **alternativ** som finns med för- och nackdelar, och en **rekommendation**, tydligt markerad som rekommendation.
3. Vänta på användarens val.

Utan uttryckligt ja från användaren görs aldrig: nedladdning eller installation, byte av verktyg eller bibliotek, egen omväg, ändrat scope eller överhoppat steg, ändringar utanför tasken, eller nytt tillvägagångssätt jämfört med det som godkänts.

**Fel i användarens egen kod** (läge `learn`): Claude ger inte lösningen direkt utan följer ledtrådstrappan i `modes/learn.md`.

Sub-agenter följer samma regel: de stannar och rapporterar tillbaka, och frågan förs vidare till användaren.

Enda undantaget: köra exakt samma kommando en gång till vid ett uppenbart tillfälligt fel (till exempel en nätverksspik), utan att ändra något. Fallerar det igen gäller regeln fullt ut.

## 13. Gemensamma resurser

Det här repot (`workflow-template`) innehåller `WORKFLOW.md`, lägesfilerna i `modes/`, `labels.json` och issue- och PR-mallarna. Den globala `CLAUDE.md` hämtar in `WORKFLOW.md` och lägesfilerna, så reglerna läses i varje session i alla projekt. I ett nytt projekt skapar Claude labels och kopierar mallarna från det här repot när användaren ber om det. Att köra `/issue` räknas som att be om det: saknas labels, board eller milestone skapas de direkt.

Skillen `/issue` ligger i `skills/issue/` och är länkad till `~/.claude/skills/issue`, så den finns i alla projekt.

## 14. Lärande och test först

Styrs av läget (regel 0):

- `learn`: lärlogg efter varje task, användaren skriver testet först före svåra områden, och Claude förklarar nya begrepp. Se `modes/learn.md`.
- `build`: Claude skriver testerna först för kärnfunktioner, användaren godkänner dem, sedan implementerar Claude. Se `modes/build.md`.
