# Mettre PhishGuard en production

Trois étapes : mettre le serveur en ligne, créer la clé de signature, publier l'APK.

## 1. Mettre le serveur en ligne (Render, gratuit)

1. Créer un compte sur https://render.com (connexion avec GitHub).
2. **New → Blueprint**, choisir le dépôt `rayenbm04/phishguard`. Render lit `render.yaml`.
3. Remplir les clés demandées : `GOOGLE_SAFE_BROWSING_API_KEY`, `VIRUSTOTAL_API_KEY`, `LLM_API_KEY`.
4. Attendre le déploiement, puis ouvrir `https://<nom>.onrender.com/health` : `{"status":"ok"}`.

À savoir sur l'offre gratuite :
- le serveur **s'endort après 15 minutes** sans requête ; le réveil prend environ une minute.
  **Avant une démonstration, ouvrir `/health` dans un navigateur** pour le réveiller ;
- les fichiers de `var/` (avis, signalements) sont effacés à chaque redéploiement.
  Récupérer les statistiques avec `/stats` avant de redéployer.

## 2. Créer la clé de signature (une seule fois)

```powershell
keytool -genkey -v -keystore D:\keys\phishguard.jks -keyalg RSA -keysize 2048 -validity 10000 -alias phishguard
```

- Garder `phishguard.jks` et ses mots de passe **hors du dépôt** (et en lieu sûr : sans elle,
  on ne peut plus publier de mise à jour de l'application).
- Copier `app/android/key.properties.example` en `app/android/key.properties` et le remplir.

Construire l'APK signé sur un PC :

```powershell
cd app
flutter build apk --release --dart-define=API_URL=https://<nom>.onrender.com
```

L'APK est dans `app\build\app\outputs\flutter-apk\app-release.apk`.

## 3. Publier une version sur GitHub

Une fois pour toutes, dans **Settings → Secrets and variables → Actions** :
- **Variables** : `API_URL` = `https://<nom>.onrender.com`
- **Secrets** (facultatif, pour signer avec la clé de l'équipe) :
  `ANDROID_KEYSTORE_BASE64` (sortie de `[Convert]::ToBase64String([IO.File]::ReadAllBytes("D:\keys\phishguard.jks"))`),
  `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.

Puis, depuis `main` à jour :

```powershell
git tag v1.0
git push origin v1.0
```

Le workflow **Release** lance les tests, construit l'APK et le publie sur la page *Releases*
(`PhishGuard-v1.0.apk`). Pour l'installer : ouvrir le lien sur le téléphone, télécharger,
autoriser « Installer des applications inconnues ».
