# Historique des versions

Chaque version correspond à une étape du plan de travail et à une étiquette Git.

## v1.0 — Version finale
- APK de production : signature avec la clé de l'équipe (`android/key.properties`), règles R8 pour ML Kit.
- Publication automatique : pousser une étiquette `v*` construit l'APK et le met sur la page *Releases* de GitHub.
- Serveur prêt à être mis en ligne : `server/Dockerfile` et `render.yaml` (Render, offre gratuite).
- Documentation finale (README, guide de mise en production `docs/RELEASE.md`).

## v0.6 — Avis et précision
- Noter un verdict (1 à 5 étoiles, commentaire) ou le signaler comme arnaque (SD6).
- Serveur : verdicts gardés sans le message, avis, signalements à relire, `GET /stats`.
- `python -m phishguard_server.evaluate` : précision, rappel et couverture sur un jeu étiqueté.
- Les vrais codes de banque (« ne le communiquez à personne ») ne sont plus signalés.

## v0.5 — Finitions de l'application
- Interface en français, arabe (de droite à gauche) et anglais.
- Premier lancement : promesses de confidentialité, accord, puis choix de la langue (SD4).
- Réglages : langue, effacer l'historique.
- Vérifier une capture d'écran : texte lu sur le téléphone, puis confirmé (SD3).
- L'explication suit la langue de l'application.

## v0.4 — Explication par l'IA
- L'IA (Groq ou Gemini, gratuits) écrit le résumé, les raisons et les conseils ; elle ne décide jamais du verdict.
- Analyse du texte seul, comparaison avec des arnaques connues, contacts officiels vérifiés.

## v0.3 — Analyse côté serveur
- Google Safe Browsing, VirusTotal, âge du domaine (RDAP), imitation de marques tunisiennes.
- Règles fixes de décision : un contrôle en échec ne donne jamais « sûr ».

## v0.2 — Parcours principal
- Écrans Accueil, Vérification, Résultat ; partage depuis WhatsApp / SMS ; masquage des numéros ; historique.

## v0.1 — Modèles partagés et serveur de base
- Contrat JSON commun à l'app et au serveur, squelette FastAPI, intégration continue.

## v0.0 — Dépôt
- Monodépôt `app/`, `server/`, `docs/`, modèles d'issues et de pull requests.
