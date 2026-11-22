# PhishGuard

Application Android qui dit si un SMS, un e-mail ou un lien est une arnaque, et explique pourquoi avec ses sources.
Projet d'équipe SUP'COM (INDP2 F, 2026/2027), encadré par Dr. Maroua Nouioua.

Équipe : BEN MIMOUN Rayen, BEN TAMARZIZT Mahdi, GARMA Nour El Houda, TOUHAMI Ayoub.

## Structure

```text
app/      application Flutter (Android)
server/   API FastAPI + pipeline d'analyse LangGraph (Python)
docs/     diagrammes UML (StarUML + PNG) et rapports
.github/  modèles d'issue et de pull request
```

## Lancer l'application

```bash
cd app
flutter pub get
flutter run
```

## Lancer le serveur

Disponible à partir de l'étape 1 (voir `server/README.md`).

## Travailler sur le dépôt

- `main` reste stable : tout passe par une branche et une pull request relue.
- Une branche par issue : `feat/12-share-intent`, `fix/20-mask-cin`, `chore/...`, `docs/...`.
- Commits au format Conventional Commits : `feat(app): receive shared text`.
- Un tag à la fin de chaque étape : `v0.0`, `v0.1`, ... `v1.0`.
- Aucune clé d'API dans Git : elles vont dans `server/.env` (ignoré).
