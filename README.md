# Municipal Elections API (COMP4977 Assignment 1 — Part 1)

ASP.NET Core Web API (.NET 10) for the **Municipal Elections Companion** iOS app.
EF Core code-first with SQLite, ASP.NET Core Identity for users, JWT bearer authentication, deployed to Azure App Service.

## Project layout

```
MunicipalElections.sln
MunicipalElections.Api/
  Program.cs                  DI, Identity, JWT, Swagger, startup migration
  Models/                     ApplicationUser, Municipality, Position, Candidate, SavedCandidate
  Data/AppDbContext.cs        IdentityDbContext + relationships
  Data/SeedData.cs            HasData seed: 3 municipalities, 9 positions, 19 candidates
  Data/DbInitializer.cs       Applies migrations + creates the demo user on startup
  DTOs/                       Request/response shapes (entities are never returned directly)
  Services/TokenService.cs    Issues JWTs
  Controllers/                Auth, Municipalities, Positions, Candidates, SavedCandidates
  MunicipalElections.Api.http Ready-made requests for VS / VS Code / Rider
```

## Run locally

Prerequisite: .NET 10 SDK.

```bash
cd MunicipalElections.Api

# one-time: EF Core CLI
dotnet tool install --global dotnet-ef

# create the code-first migration (do this once, then commit the Migrations folder)
dotnet ef migrations add InitialCreate

dotnet run --launch-profile http
```

Open http://localhost:5080/swagger. The database (`elections.db`) is created and seeded automatically on first run.

> If you skip the migration step the app still starts (it falls back to `EnsureCreated`), but the marking scheme asks for EF Core **code-first**, so generate and commit the migration.

**Demo account** (created on startup): `demo@elections.ca` / `Demo123!`
Remove the `DemoUser` section in `appsettings.json` to disable it.

### Trying protected endpoints in Swagger
1. `POST /api/auth/login` with the demo account, copy `token`.
2. Click **Authorize**, paste the token (no `Bearer ` prefix), then call `/api/savedcandidates`.

## API endpoints

| Method | Route | Auth | Notes |
|---|---|---|---|
| POST | `/api/auth/register` | — | Body `{ name, email, password }` → **201** `{ token, expiresAt, user }` |
| POST | `/api/auth/login` | — | Body `{ email, password }` → **200** `{ token, expiresAt, user }`, **401** on bad credentials |
| GET | `/api/auth/me` | Bearer | Current user `{ id, name, email }` (Profile screen) |
| GET | `/api/municipalities` | — | List with `candidateCount` |
| GET | `/api/municipalities/{id}` | — | Includes `positions` |
| GET | `/api/positions` | — | Optional `?municipalityId=` |
| GET | `/api/positions/{id}` | — | |
| GET | `/api/candidates` | — | Optional `?municipalityId=&positionId=&name=` (for app filtering) |
| GET | `/api/candidates/{id}` | — | |
| GET | `/api/candidates/search?name=` | — | Partial, case-insensitive name match |
| GET | `/api/savedcandidates` | Bearer | Current user's voting guide (each item embeds the candidate) |
| POST | `/api/savedcandidates` | Bearer | Body `{ candidateId }` → **201**; **404** unknown candidate; **409** already saved |
| DELETE | `/api/savedcandidates/{id}` | Bearer | `id` = `savedCandidateId` → **204** |
| DELETE | `/api/savedcandidates/candidate/{candidateId}` | Bearer | Extra: remove by candidate (handy for a toggle button) → **204** |

### JSON notes for the Swift client
- Property names are camelCase (`municipalityId`, `electionDate`, `photoUrl`, …).
- `electionDate` is a plain date string: `"2026-10-17"`.
- `dateSaved` and `expiresAt` are ISO-8601 UTC with fractional seconds, e.g. `"2026-10-22T22:41:07.1234567Z"`.
- Errors use RFC 7807 problem details: `{ "title": "...", "status": 409, ... }`.
  Validation errors (400) also include `errors: { "Field": ["message"] }`.

### Password rules
Minimum 6 characters (no other complexity requirements), unique email. Match this in the app's validation.

## Database (ERD summary)

```
AspNetUsers (ApplicationUser: Id, FullName, Email, ...)
   1 ──< SavedCandidate (SavedCandidateId, UserId, CandidateId, DateSaved)  [unique UserId+CandidateId]
                                     >── 1 Candidate
Municipality (MunicipalityId, Name, Province, ElectionDate, Description, LogoUrl)
   1 ──< Position (PositionId, Name, SeatsAvailable, MunicipalityId)
   1 ──< Candidate (CandidateId, Name, Biography, PhotoUrl, Website, Email, PositionId, MunicipalityId)
Position 1 ──< Candidate
```

Seed: Pitt Meadows, Maple Ridge, Burnaby; each has Mayor, Councillor and School Trustee; 19 fictional candidates (≥ 2 per position). Photos/logos are generated placeholder images.

## Deploy to Azure App Service

SQLite needs a persistent, writable file, so use **App Service** (not Azure Functions) with a **single instance**. On Azure the app stores the database at `$HOME/data/elections.db` (persistent storage), and applies migrations + seed on startup.

### Option A — Azure CLI (quickest)
```bash
az login
cd MunicipalElections.Api
az webapp up --name <unique-app-name> --resource-group comp4977-rg \
  --runtime "DOTNETCORE:10.0" --sku B1 --os-type Linux

# set a real JWT signing key (32+ characters)
az webapp config appsettings set --name <unique-app-name> --resource-group comp4977-rg \
  --settings Jwt__Key="$(openssl rand -base64 48)"
```
(`--sku F1` is free but may sleep; B1 is more reliable for marking.)

### Option B — Visual Studio / Rider
Right-click the project → **Publish** → Azure → Azure App Service (Linux) → create new → .NET 10 runtime → Publish.
Then in the portal: **Settings → Environment variables** → add `Jwt__Key` with a long random value.

### Option C — GitHub Actions
In the portal, open the Web App → **Deployment Center** → Source: GitHub → pick the repo/branch. Azure commits a workflow file that builds and deploys on every push. Add `Jwt__Key` as above.

### Verify
- `https://municipal-elections-a1-fgdtgnewg7cedkd7.westus3-01.azurewebsites.net/swagger/index.html` loads.
- `GET /api/municipalities` returns 3 items.
- Take the "Azure deployment screenshot" of the Web App overview page + Swagger.

### Configuration reference
| Setting | Purpose | Azure env var |
|---|---|---|
| `Jwt:Key` | HMAC signing key, ≥ 32 bytes | `Jwt__Key` |
| `Jwt:Issuer` / `Jwt:Audience` | Token issuer/audience | `Jwt__Issuer` / `Jwt__Audience` |
| `Jwt:ExpiryMinutes` | Token lifetime (default 1440 = 24 h) | `Jwt__ExpiryMinutes` |
| `Database:Path` | Override SQLite file location | `Database__Path` |
| `DemoUser:*` | Demo account (blank email disables) | `DemoUser__Email` |

## Deliverable URLs
- Azure API URL: `https://municipal-elections-a1-fgdtgnewg7cedkd7.westus3-01.azurewebsites.net/`
- GitHub repository: `https://github.com/sonboiii/IOS4977-A1`
