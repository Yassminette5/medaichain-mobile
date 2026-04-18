@echo off
title MEDAIChain — Flutter Web (Chrome)
color 0B

echo.
echo  ╔══════════════════════════════════════════════════════╗
echo  ║          MEDAIChain — Lancer sur Chrome              ║
echo  ║     Beaucoup plus rapide que l'emulateur Android     ║
echo  ╚══════════════════════════════════════════════════════╝
echo.

:: ── Vérifier Flutter ────────────────────────────────────────────────────────
where flutter >nul 2>&1
if errorlevel 1 (
    echo  [ERREUR] Flutter introuvable dans le PATH.
    echo  Installez Flutter : https://docs.flutter.dev/get-started/install/windows
    echo.
    pause
    exit /b 1
)

:: ── Afficher la version Flutter ─────────────────────────────────────────────
echo  [INFO] Version Flutter detectee :
flutter --version --machine 2>nul | findstr "frameworkVersion" || flutter --version
echo.

:: ── Vérifier Chrome ─────────────────────────────────────────────────────────
set CHROME_PATH=
for %%P in (
    "C:\Program Files\Google\Chrome\Application\chrome.exe"
    "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    "%LOCALAPPDATA%\Google\Chrome\Application\chrome.exe"
) do (
    if exist %%P (
        set CHROME_PATH=%%P
        goto :chrome_found
    )
)

echo  [AVERTISSEMENT] Chrome introuvable. Flutter utilisera le navigateur par defaut.
goto :run_app

:chrome_found
echo  [OK] Chrome detecte : %CHROME_PATH%
set CHROME_EXECUTABLE=%CHROME_PATH%

:run_app
echo.
echo  ┌─────────────────────────────────────────────────────┐
echo  │  BACKEND attendu sur : http://localhost:3000         │
echo  │  Swagger  IA       : http://localhost:3000/api       │
echo  │  Serveur  IA       : http://localhost:8081           │
echo  └─────────────────────────────────────────────────────┘
echo.
echo  Assurez-vous que ces services tournent avant de continuer.
echo  - medaichain-backend : npm run start:dev
echo  - Serveur IA         : start_ai_server.bat
echo.
set /p CONFIRM="  Appuyez sur [Entree] pour lancer l'app ou Ctrl+C pour annuler..."
echo.

:: ── Choisir le mode ──────────────────────────────────────────────────────────
echo  Choisissez le mode de lancement :
echo  [1] Debug   (hot reload, logs — recommande pour tests)
echo  [2] Profile (performances reelles)
echo  [3] Release (production)
echo.
set /p MODE_CHOICE="  Votre choix [1/2/3] (Entree = 1) : "

if "%MODE_CHOICE%"=="2" (
    set FLUTTER_MODE=--profile
    echo  [Mode] Profile
) else if "%MODE_CHOICE%"=="3" (
    set FLUTTER_MODE=--release
    echo  [Mode] Release
) else (
    set FLUTTER_MODE=--debug
    echo  [Mode] Debug
)

:: ── Choisir le port ──────────────────────────────────────────────────────────
echo.
set /p PORT_CHOICE="  Port web (Entree = 8080) : "
if "%PORT_CHOICE%"=="" set PORT_CHOICE=8080

echo.
echo  ════════════════════════════════════════════════════════
echo   Lancement : flutter run -d chrome --web-port %PORT_CHOICE% %FLUTTER_MODE%
echo   URL app   : http://localhost:%PORT_CHOICE%
echo  ════════════════════════════════════════════════════════
echo.

:: ── Activer URL hash strategy (evite les 404 sur refresh) ───────────────────
set FLUTTER_WEB_USE_SKIA=true

:: ── Lancer Flutter sur Chrome ────────────────────────────────────────────────
flutter run ^
    -d chrome ^
    --web-port %PORT_CHOICE% ^
    --web-hostname localhost ^
    %FLUTTER_MODE%

:: ── En cas d'erreur ──────────────────────────────────────────────────────────
if errorlevel 1 (
    echo.
    echo  [ERREUR] Flutter a rencontre un probleme.
    echo.
    echo  Solutions courantes :
    echo  1. flutter pub get          (dependances manquantes)
    echo  2. flutter clean            (cache corrompu)
    echo  3. flutter doctor           (verifier l'installation)
    echo.
    pause
    exit /b 1
)

echo.
echo  [OK] Application fermee proprement.
pause
