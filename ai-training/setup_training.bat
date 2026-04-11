@echo off
echo 🚀 Configuration de l'environnement d'entraînement IA...

:: Check for Python
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python n'est pas installé. Veuillez l'installer sur https://www.python.org/
    pause
    exit /b
)

:: Create virtual environment
echo 📦 Création de l'environnement virtuel (venv)...
python -m venv venv
call venv\Scripts\activate

:: Update pip
python -m pip install --upgrade pip

:: Install requirements
echo 📥 Installation des dépendances (cela peut prendre du temps)...
pip install -r requirements.txt

echo ✅ Environnement prêt ! 
echo 💡 Utilisez 'venv\Scripts\activate' pour activer l'environnement.
pause
