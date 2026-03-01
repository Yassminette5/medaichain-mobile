# Appel vidéo médecin–patient (Agora)

## Configuration backend

1. Créer un projet sur [Agora Console](https://console.agora.io).
2. Récupérer l’**App ID** et le **Certificate** (Primary).
3. Dans le backend, ajouter dans `.env` :
   ```
   AGORA_APP_ID=votre_app_id
   AGORA_APP_CERTIFICATE=votre_certificate
   ```
4. Redémarrer le backend.

## Côté patient

- Depuis la fiche d’un médecin (liste des médecins ou « Top Doctors »), appuyer sur **Video**.
- L’app ouvre l’écran d’appel et rejoint le canal commun avec ce médecin.

## Côté médecin

- Sur le tableau de bord, appuyer sur **Appel Vidéo**.
- Choisir un patient dans la liste.
- L’app lance l’appel ; le patient peut rejoindre depuis la fiche du médecin (bouton Video).

## Permissions

- **Android** : `CAMERA`, `RECORD_AUDIO`, `MODIFY_AUDIO_SETTINGS`, `INTERNET` (déjà dans `AndroidManifest.xml`).
- **iOS** : ajouter dans `Info.plist` les clés `NSCameraUsageDescription` et `NSMicrophoneUsageDescription`.
