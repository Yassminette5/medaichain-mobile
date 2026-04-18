@echo off
title MEDAIChain — Lancer sur Telephone Reel (USB)
color 0A

echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║       MEDAIChain — Test sur Telephone Reel (USB)         ║
echo  ║   10x plus rapide que l'emulateur — 100%% natif          ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

:: ── Verifier Flutter ────────────────────────────────────────────────────────
where flutter >nul 2>&1
if errorlevel 1 (
    echo  [ERREUR] Flutter introuvable dans le PATH.
    echo  Installez Flutter : https://docs.flutter.dev/get-started/install/windows
    pause
    exit /b 1
)

:: ── Verifier ADB ─────────────────────────────────────────────────────────────
where adb >nul 2>&1
if errorlevel 1 (
    echo  [AVERTISSEMENT] ADB introuvable dans le PATH.
    echo  Installez Android SDK Platform Tools :
    echo  https://developer.android.com/tools/releases/platform-tools
    echo.
    echo  Ou ajoutez ce dossier au PATH :
    echo  C:\Users\%USERNAME%\AppData\Local\Android\Sdk\platform-tools
    echo.
    pause
    exit /b 1
)

echo  [OK] Flutter et ADB detectes.
echo.

:: ── Verifier les appareils connectes ─────────────────────────────────────────
echo  ┌─────────────────────────────────────────────────────────┐
echo  │  Appareils connectes (adb devices) :                    │
echo  └─────────────────────────────────────────────────────────┘
adb devices -l
echo.

:: Compter les vrais appareils (hors "List of devices" et "emulator")
for /f "skip=1 tokens=1,2" %%A in ('adb devices') do (
    if "%%B"=="device" (
        echo  [OK] Appareil detecte : %%A
        goto :device_found
    )
)

echo  [ERREUR] Aucun telephone detecte.
echo.
echo  Verifiez :
echo  1. Le cable USB est bien branche
echo  2. Le debogage USB est ACTIVE sur le telephone :
echo     Parametres ^> A propos ^> Numero de build (appuyer 7x)
echo     Parametres ^> Options developpeur ^> Debogage USB = ON
echo  3. Appuyez "Autoriser" sur le telephone quand il vous le demande
echo  4. Essayez : adb kill-server  puis  adb start-server
echo.
pause
exit /b 1

:device_found
echo.

:: ── Detecter l'IP locale du PC (pour que le telephone contacte le backend) ───
echo  ┌─────────────────────────────────────────────────────────┐
echo  │  Detection de l'IP locale du PC...                      │
echo  └─────────────────────────────────────────────────────────┘

set PC_IP=
for /f "tokens=2 delims=:" %%A in ('ipconfig ^| findstr /i "IPv4"') do (
    set RAW_IP=%%A
    :: Nettoyer les espaces
    for /f "tokens=1" %%B in ("%%A") do (
        set CANDIDATE=%%B
        :: Prendre la premiere IP non-loopback (pas 127.x)
        echo %%B | findstr /v "^127\." >nul 2>&1
        if not errorlevel 1 (
            if "!PC_IP!"=="" set PC_IP=%%B
        )
    )
)

:: Fallback si la detection automatique echoue
if "%PC_IP%"=="" (
    echo  [AVERTISSEMENT] IP auto-detectee introuvable.
    echo  Entrez manuellement l'IP de votre PC (commande : ipconfig)
    echo  Exemple : 192.168.1.100
    echo.
    set /p PC_IP="  Votre IP locale : "
) else (
    echo  [OK] IP detectee : %PC_IP%
    echo.
    echo  Cette IP sera utilisee par le telephone pour contacter le backend.
    set /p CONFIRM_IP="  Confirmer [O/n] (Entree = Oui) : "
    if /i "%CONFIRM_IP%"=="n" (
        set /p PC_IP="  Entrez l'IP manuellement : "
    )
)

echo.
echo  [Config] Backend URL = http://%PC_IP%:3000
echo.

:: ── Patcher main.dart avec la bonne IP ───────────────────────────────────────
echo  ┌─────────────────────────────────────────────────────────┐
echo  │  Mise a jour de l'IP dans main.dart...                  │
echo  └─────────────────────────────────────────────────────────┘

set MAIN_DART=lib\main.dart

:: Verifier que main.dart existe
if not exist "%MAIN_DART%" (
    echo  [ERREUR] lib\main.dart introuvable.
    echo  Assurez-vous d'etre dans le bon dossier.
    pause
    exit /b 1
)

:: Remplacer la ligne backendUrlOverride dans main.dart
:: On cree un fichier temp puis on remplace
powershell -Command "(Get-Content '%MAIN_DART%') -replace '(//\s*)?ApiService\.backendUrlOverride\s*=.*', 'ApiService.backendUrlOverride = ''http://%PC_IP%:3000'';' | Set-Content '%MAIN_DART%'"

if errorlevel 1 (
    echo  [AVERTISSEMENT] Impossible de patcher main.dart automatiquement.
    echo.
    echo  Faites-le manuellement dans lib\main.dart :
    echo  Decommentez et modifiez cette ligne :
    echo.
    echo    ApiService.backendUrlOverride = 'http://%PC_IP%:3000';
    echo.
    pause
)

echo  [OK] main.dart mis a jour avec IP = %PC_IP%
echo.

:: ── Ouvrir le pare-feu pour le port 3000 ─────────────────────────────────────
echo  ┌─────────────────────────────────────────────────────────┐
echo  │  Ouverture du port 3000 dans le pare-feu Windows...     │
echo  └─────────────────────────────────────────────────────────┘

netsh advfirewall firewall show rule name="MEDAIChain Backend 3000" >nul 2>&1
if errorlevel 1 (
    netsh advfirewall firewall add rule ^
        name="MEDAIChain Backend 3000" ^
        dir=in ^
        action=allow ^
        protocol=TCP ^
        localport=3000 >nul 2>&1
    if errorlevel 1 (
        echo  [AVERTISSEMENT] Impossible d'ajouter la regle pare-feu (droits admin requis).
        echo  Si le telephone ne peut pas acceder au backend, lancez ce .bat en tant qu'Administrateur.
    ) else (
        echo  [OK] Port 3000 autorise dans le pare-feu Windows.
    )
) else (
    echo  [OK] Regle pare-feu deja existante.
)
echo.

:: ── Verifier que le backend tourne ───────────────────────────────────────────
echo  ┌─────────────────────────────────────────────────────────┐
echo  │  Verification du backend sur localhost:3000...          │
echo  └─────────────────────────────────────────────────────────┘

curl -s -o nul -w "%%{http_code}" http://localhost:3000 >nul 2>&1
if errorlevel 1 (
    echo  [AVERTISSEMENT] Backend semble eteint (curl indisponible ou timeout).
    echo  Lancez : npm run start:dev  dans medaichain-backend\
    echo.
) else (
    echo  [OK] Backend repond sur localhost:3000
    echo.
)

:: ── Choisir le mode de lancement ─────────────────────────────────────────────
echo  ┌─────────────────────────────────────────────────────────┐
echo  │  Mode de lancement :                                    │
echo  └─────────────────────────────────────────────────────────┘
echo  [1] Debug   (hot reload actif — recommande pour tests IA)
echo  [2] Profile (performances reelles)
echo  [3] Release (build final)
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
    echo  [Mode] Debug avec hot reload (r = reload, R = restart)
)

echo.

:: ── Lister les appareils Flutter disponibles ─────────────────────────────────
echo  ┌─────────────────────────────────────────────────────────┐
echo  │  Appareils Flutter disponibles :                        │
echo  └─────────────────────────────────────────────────────────┘
flutter devices
echo.

:: ── Lancer l'application ─────────────────────────────────────────────────────
echo  ════════════════════════════════════════════════════════════
echo   Lancement : flutter run %FLUTTER_MODE%
echo   Backend   : http://%PC_IP%:3000
echo   Swagger   : http://localhost:3000/api
echo  ════════════════════════════════════════════════════════════
echo.
echo  Raccourcis pendant l'execution :
echo    r  = Hot reload
echo    R  = Hot restart
echo    q  = Quitter
echo    i  = Inspecter widget
echo.

flutter run %FLUTTER_MODE%

:: ── Restaurer main.dart apres le test ────────────────────────────────────────
echo.
echo  ┌─────────────────────────────────────────────────────────┐
echo  │  Restauration de main.dart (commenter l'IP)...          │
echo  └─────────────────────────────────────────────────────────┘

powershell -Command "(Get-Content '%MAIN_DART%') -replace '^(\s*)ApiService\.backendUrlOverride\s*=.*', '$1// ApiService.backendUrlOverride = ''http://%PC_IP%:3000''; // Decommentez pour telephone reel' | Set-Content '%MAIN_DART%'"

echo  [OK] main.dart restaure (IP commentee).
echo.

if errorlevel 1 (
    echo  [INFO] App fermee avec code d'erreur. Verifiez les logs ci-dessus.
) else (
    echo  [OK] Session terminee proprement.
)

echo.
pause
