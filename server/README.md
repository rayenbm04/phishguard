# Serveur PhishGuard

API FastAPI (Python 3.10 ou plus, 3.12 en CI). `/analyse` lance le pipeline des diagrammes
SD2 et SD3 ; depuis l'étape 4, l'IA rédige l'explication dans la langue du message.

## Lancer en local (PowerShell)

```powershell
cd server
python -m venv .venv                          
.venv\Scripts\python -m pip install -e ".[dev]"
copy .env.example .env                         
.venv\Scripts\python -m uvicorn phishguard_server.main:app --host 0.0.0.0 --reload
```

Puis ouvrir http://127.0.0.1:8000/docs pour tester `/health`, `/analyse` et `/feedback`.

## Clés d'API (dans `server/.env`, jamais dans Git)

| Variable | Où l'obtenir | Sans la clé |
| --- | --- | --- |
| `GOOGLE_SAFE_BROWSING_API_KEY` | Google Cloud Console → activer « Safe Browsing API » → Identifiants → Clé API | le contrôle échoue → verdict au mieux `UNSURE` |
| `VIRUSTOTAL_API_KEY` | virustotal.com → profil → API Key (gratuit, 4 requêtes/min) | idem |
| `LLM_API_KEY` | Gratuit : Gemini (aistudio.google.com → Get API key, `LLM_PROVIDER=gemini`) ou Groq (console.groq.com → API Keys, `LLM_PROVIDER=groq`) | explication en phrases modèles (anglais), verdict identique |

RDAP (âge des domaines) ne demande pas de clé. Les domaines `.tn` n'ont pas de RDAP public.

## Comment le verdict est décidé

`AnalysisPipeline` (dans `phishguard_server/analysis/`) :

1. `InjectionGuard` retire les instructions cachées destinées à l'IA et les garde comme preuve.
2. `ClueExtractor` trouve les liens, montants, numéros, expéditeurs et mots urgents.
3. `KnownScamMatcher` compare avec les campagnes connues (`data/known_scams.json`) et
   `TextHeuristicCheck` cherche les signes dans les mots (code secret demandé, frais à payer,
   menace de blocage, cadeau, « j'ai changé de numéro », urgence).
4. En parallèle (5 s max) :
   - `LinkReputationCheck` : Google Safe Browsing, puis VirusTotal seulement si le lien n'est pas
     listé ; résultats gardés 6 h dans `ReputationCache` ;
   - `DomainCheck` : âge du domaine (RDAP), imitation d'une marque tunisienne, extension risquée,
     lien raccourci, adresse IP.
5. `SafetyRules` décide (jamais l'IA) :
   - lien sur liste noire → `FRAUDULENT` ;
   - imitation d'une marque sur un site neuf ou risqué → `FRAUDULENT` ;
   - sinon le score de risque décide (≥ 70 `FRAUDULENT`, ≥ 35 `SUSPICIOUS`) ;
   - des instructions cachées pour l'IA → au moins `SUSPICIOUS` ;
   - un contrôle `FAILED` ne donne jamais `SAFE` → `UNSURE` ;
   - un message sans lien n'est `SAFE` que s'il ne montre aucun signe et ne demande ni appel
     ni paiement ; sinon `UNSURE`.
6. `LLMExplainer` rédige le résumé, les 3 raisons et les conseils dans la langue du message.
   Il ne peut que reformuler : chaque raison doit citer une preuve, chaque contact vient de
   `OfficialContactDirectory`, les liens écrits par l'IA sont supprimés, le texte du message
   lui est donné comme donnée non fiable. Si l'IA échoue ou dépasse le temps restant (le tout
   tient en 7,3 s), `TemplateExplainer` répond en phrases modèles.

## Tests et style

```powershell
.venv\Scripts\python -m pytest -q
.venv\Scripts\python -m ruff check .
.venv\Scripts\python -m ruff format .
```

Les tests n'appellent jamais Google, VirusTotal ou RDAP : `tests/fakes.py` les simule.

## Avis des utilisateurs et mesure de la précision (étape 6)

- Chaque verdict est enregistré **sans le message** (id, niveau, score, langue) dans `var/verdicts.jsonl`.
- `POST /feedback` enregistre une note (1 à 5 étoiles) et/ou un signalement dans `var/feedback.jsonl`.
  Le texte masqué n'est accepté qu'avec un signalement ; il va dans `var/scam_candidates.jsonl`
  (statut `to_review`), pour être relu par l'équipe avant d'entrer dans `data/known_scams.json`.
- `GET /stats` donne la note moyenne, la part de notes 4-5 étoiles (`helpfulRate`) et les
  arnaques signalées alors que le verdict était `SAFE` (`missedScams`).
- Précision sur un jeu de messages étiquetés (`data/eval_set.jsonl`, synthétique : ajoutez de vrais
  messages anonymisés) :

```powershell
.venv\Scripts\python -m phishguard_server.evaluate            # règles seules, sans réseau
.venv\Scripts\python -m phishguard_server.evaluate --online   # avec les vrais services (.env)
```

Il affiche précision, rappel, F1, couverture (part de réponses autres que `UNSURE`) et la liste des erreurs.

## Points d'entrée

| Méthode | Chemin | Rôle |
| --- | --- | --- |
| GET | `/health` | Le serveur répond |
| POST | `/analyse` | Reçoit un `AnalyseRequest`, renvoie un `Verdict` |
| POST | `/feedback` | Reçoit une note ou un signalement |
| GET | `/stats` | Statistiques : verdicts par niveau, note moyenne, arnaques manquées |

Les modèles sont dans `phishguard_server/models.py` ; les exemples JSON partagés avec l'app
sont dans `../contracts/`.
