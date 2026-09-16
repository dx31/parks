# Parkímetro

Bosquejo inicial: API .NET 10 + app Flutter de operador + app Flutter de cliente.

Los scripts de visión (`main.py`, `selector.py`) se quedan en la raíz para integrarlos después.

## Cómo correrlo

API:

```powershell
dotnet run --project api/Parkimetro.Api.csproj --launch-profile http
```

Queda en `http://localhost:5280`.


```powershell
cd apps/operator
D:\flutter\bin\flutter.bat run
```

App cliente:

```powershell
cd apps/client
D:\flutter\bin\flutter.bat run
```

Las apps Flutter eligen la URL de la API según el entorno:

- Desarrollo (`flutter run` / debug): `http://localhost:5280` (emulador Android: `http://10.0.2.2:5280`)
- Producción: no va en el repo. Copia `api_env.example.json` a `api_env.json` (está en `.gitignore`) y compila así:

```powershell
Copy-Item api_env.example.json api_env.json
D:\flutter\bin\flutter.bat run --release --dart-define-from-file=api_env.json
```

También puedes pasar la URL al vuelo, sin dejarla en un archivo:

```powershell
D:\flutter\bin\flutter.bat run --release --dart-define=API_PROD_URL=https://tu-api.com
D:\flutter\bin\flutter.bat run --dart-define=API_DEV_URL=http://192.168.1.10:5280
```

Panel web admin (DaisyUI), usuario `ana`, PIN `1234`:

```powershell
cd apps/admin
npm install
npm run dev
```

Queda en `http://localhost:5174`. En desarrollo proxy hacia la API local. Para producción, copia `apps/admin/.env.example` a `apps/admin/.env` y corre `npm run build`.

Swagger UI (solo en desarrollo, no en producción): `http://localhost:5280/swagger`

OpenAPI: `http://localhost:5280/openapi/v1.json`

## Pruebas y quality gates

API:

```powershell
dotnet format parks.slnx --verify-no-changes --severity warn
dotnet test tests/Parkimetro.Api.Tests/Parkimetro.Api.Tests.csproj /p:CollectCoverage=true /p:Threshold=70
```

Flutter:

```powershell
dart format --set-exit-if-changed apps/parkimetro_core apps/operator apps/client
cd apps/parkimetro_core; D:\flutter\bin\flutter.bat test
cd ../operator; D:\flutter\bin\flutter.bat test; D:\flutter\bin\flutter.bat test integration_test
cd ../client; D:\flutter\bin\flutter.bat test; D:\flutter\bin\flutter.bat test integration_test
```

Las pruebas `integration_test` de Flutter se corren en un dispositivo:

```powershell
D:\flutter\bin\flutter.bat test integration_test -d windows
```

CI corre lo mismo en `.github/workflows/ci.yml`: format, build con warnings como error, tests de unidad e integración, coverage mínimo 70% en la API y `flutter analyze`.

## Secreto de la API en GitHub

La URL de producción no va en el código. En el repo:

1. Settings → Secrets and variables → Actions → New repository secret
2. Name: `API_PROD_URL`
3. Value: la URL de tu API (por ejemplo `https://tu-api.com`)

El workflow `.github/workflows/release-apps.yml` la inyecta al compilar los APKs (también corre en `main`/`master` después de que pase el CI):

```text
flutter build apk --release --dart-define-from-file=api_env.json
```

`api_env.json` se genera en el runner a partir del secreto y no se sube al repo. Se dispara a mano (Actions → Release apps → Run workflow), al pushear a `main`, o al subir un tag `v*`. Los APKs quedan en Artifacts. El job de pruebas no usa este secreto: corre en debug contra la API local.

Android Studio en tu PC no lee los secretos de GitHub; ahí sigue valiendo `main.dart (producción)` o `api_env.json`.

## Qué incluye este bosquejo

- Zonas y espacios de parquímetro
- Estados: libre, ocupado, reservado, fuera de servicio
- Login simple de operador
- Sesión de ocupación con placa opcional
- Consulta de espacios para clientes
- Datos de ejemplo al arrancar la API (SQLite `api/parkimetro.db`)
