# Dairy Milk Collection & Sales Management System

## Prerequisites
- .NET 8 SDK
- PostgreSQL 14+
- Node.js (for frontend build, if needed)
- Android Studio (for MobileApp)

## Setup & Run (Web)
1. Update `appsettings.json` with your PostgreSQL credentials.
2. Run DB scripts in `/Scripts/postgres` to create and seed the database.
3. In `/src/Web`, run:
   ```
dotnet run
   ```
4. Access the app at `https://localhost:5001`.

## Android App
1. Open `/src/MobileApp` in Android Studio.
2. Build and run the app on emulator/device.
3. Configure API base URL in app settings.

## Localization
- Add new language: create new `.resx` in `/src/Localization` and new `values-xx` folder in Android.
- Add culture code to `SupportedCultures` in `appsettings.json`.

## Export/Reporting
- Excel: ClosedXML
- PDF: QuestPDF

## Testing
- Run unit/integration tests in `/tests`:
   ```
dotnet test
   ```

## Deployment
- Use Docker Compose for Postgres, pgAdmin, and Web API (optional).
- See sample `docker-compose.yml`.

## API Collection
- See `/Scripts/postman_collection.json` for all endpoints.

## CI/CD
- See `.github/workflows/ci.yml` for GitHub Actions skeleton.

---
For any issues, see documentation or contact the maintainer.
