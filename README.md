# PhishGuard

Application Android qui dit si un SMS, un e-mail ou un lien est une arnaque, explique pourquoi
et indique quoi faire. Pensée pour la Tunisie : français, arabe et anglais, marques et arnaques locales.

Projet d'équipe SUP'COM (INDP2 F, 2026/2027), encadré par Dr. Maroua Nouioua.
Équipe : BEN MIMOUN Rayen, BEN TAMARZIZT Mahdi, GARMA Nour El Houda, TOUHAMI Ayoub.

**Télécharger l'application :** page *Releases* du dépôt (`PhishGuard-v1.0.apk`).

## Ce que fait PhishGuard

- **Vérifier un message** : le partager depuis WhatsApp, SMS ou Gmail, le coller, l'écrire, ou
  choisir une capture d'écran (texte lu sur le téléphone).
- **Protéger la vie privée** : les numéros de téléphone, de carte et de CIN sont masqués sur le
  téléphone avant tout envoi ; aucun compte ; l'historique reste sur le téléphone.
- **Un verdict clair** : Arnaque, Suspect, Semble sûr ou Incertain, avec un score de risque,
  les 3 raisons principales (et leur source) et les conseils, avec le site officiel de la marque imitée.
- **Une analyse fiable** : liens vérifiés (Google Safe Browsing, VirusTotal), âge du domaine,
  imitation de marques tunisiennes, signes dans le texte, arnaques connues. **Des règles fixes
  décident du verdict ; l'IA ne fait que l'expliquer**, dans la langue de l'utilisateur.
  Un contrôle qui échoue ne donne jamais « sûr ».
- **S'améliorer** : noter un verdict, signaler une arnaque ; statistiques et mesure de la précision.

## Structure

```text
app/      application Flutter (Android)
server/   API FastAPI et pipeline d'analyse (Python)
contracts/ exemples JSON partagés par l'app et le serveur
docs/     diagrammes UML (StarUML + PNG), mise en production
.github/  intégration continue, publication de l'APK, modèles d'issue et de PR
```

## Lancer en local

Serveur (détails et clés d'API : `server/README.md`) :

```powershell
cd server
python -m venv .venv
.venv\Scripts\python -m pip install -e ".[dev]"
.venv\Scripts\python -m uvicorn phishguard_server.main:app --host 0.0.0.0 --reload
```

Application (émulateur Android lancé) :

```powershell
cd app
flutter pub get
flutter run
```

Sur un vrai téléphone, sur le même Wi-Fi que le PC :
`flutter run --dart-define=API_URL=http://<IP-du-PC>:8000`.

## Tests

```powershell
cd app;    flutter analyze; flutter test
cd server; .venv\Scripts\python -m pytest -q
cd server; .venv\Scripts\python -m phishguard_server.evaluate   # précision sur un jeu étiqueté
```

## Mise en production

Serveur sur Render, APK signé et publication automatique : voir [`docs/RELEASE.md`](docs/RELEASE.md).
Historique des versions : [`CHANGELOG.md`](CHANGELOG.md).

## Travailler sur le dépôt

- `main` reste stable : tout passe par une branche et une pull request relue.
- Une branche par sujet : `feat/...`, `fix/...`, `chore/...`, `docs/...`.
- Commits au format Conventional Commits : `feat(app): receive shared text`.
- Une étiquette à la fin de chaque étape : `v0.0` … `v1.0`.
- Aucune clé dans Git : clés d'API dans `server/.env`, clé de signature dans `app/android/key.properties`.
