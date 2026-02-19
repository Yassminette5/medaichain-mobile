# 🌐 Admin Dashboard (Flutter Web)

Le code source de l'interface d'administration n'est **PAS** dans ce dossier `web/`.
En Flutter, tout le code (Web, Android, iOS) se trouve dans le dossier `lib/`.

## 📂 Où trouver le code ?

### 1. Écrans (L'interface visuelle) :
Le code des pages Admin se trouve dans :
`../lib/screens/admin/`

- **Page de Connexion** : `admin_login_screen.dart`
- **Tableau de Bord** : `admin_dashboard_screen.dart`

### 2. Logique (Appels API) :
La gestion des données se trouve dans :
`../lib/services/`
- **Service Admin** : `admin_service.dart`

---

## 🚀 Comment lancer ?

Ouvrez un terminal à la racine du projet (`medecin_app`) et lancez :

```bash
flutter run -d chrome
```

Cela ouvrira Chrome et affichera automatiquement le Dashboard Admin.
