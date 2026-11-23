# Serveur PhishGuard

API FastAPI (Python 3.10 ou plus, 3.12 en CI). Étape 3 : `/analyse` lance le vrai pipeline
(diagrammes SD2 et SD3). Les explications sont encore des phrases modèles en anglais ;
l'IA (LLMExplainer) arrive à l'étape 4.

## Lancer en local (PowerShell)

```powershell
cd server
python -m venv .venv                          # une seule fois
.venv\Scripts\python -m pip install -e ".[dev]"
copy .env.example .env                         # puis remplir les clés
.venv\Scripts\python -m uvicorn phishguard_server.main:app --host 0.0.0.0 --reload
```

Puis ouvrir http://127.0.0.1:8000/docs pour tester `/health`, `/analyse` et `/feedback`.

## Clés d'API (dans `server/.env`, jamais dans Git)

| Variable | Où l'obtenir | Sans la clé |
| --- | --- | --- |
| `GOOGLE_SAFE_BROWSING_API_KEY` | Google Cloud Console → activer « Safe Browsing API » → Identifiants → Clé API | le contrôle échoue → verdict au mieux `UNSURE` |
| `VIRUSTOTAL_API_KEY` | virustotal.com → profil → API Key (gratuit, 4 requêtes/min) | idem |

RDAP (âge des domaines) ne demande pas de clé. Les domaines `.tn` n'ont pas de RDAP public.

## Comment le verdict est décidé

`AnalysisPipeline` (dans `phishguard_server/analysis/`) :

1. `InjectionGuard` retire les instructions cachées destinées à l'IA et les garde comme preuve.
2. `ClueExtractor` trouve les liens, montants, numéros, expéditeurs et mots urgents.
3. En parallèle (6,5 s max) :
   - `LinkReputationCheck` : Google Safe Browsing, puis VirusTotal seulement si le lien n'est pas
     listé ; résultats gardés 6 h dans `ReputationCache` ;
   - `DomainCheck` : âge du domaine (RDAP), imitation d'une marque tunisienne, extension risquée,
     lien raccourci, adresse IP.
4. `SafetyRules` décide (jamais l'IA) :
   - lien sur liste noire → `FRAUDULENT` ;
   - imitation d'une marque sur un site neuf ou risqué → `FRAUDULENT` ;
   - sinon le score de risque décide (≥ 70 `FRAUDULENT`, ≥ 35 `SUSPICIOUS`) ;
   - un contrôle `FAILED` ne donne jamais `SAFE` → `UNSURE` ;
   - un message sans lien → `UNSURE` (l'analyse du texte arrive à l'étape 4).
5. `TemplateExplainer` écrit le résumé, les 3 raisons principales et les conseils.

## Tests et style

```powershell
.venv\Scripts\python -m pytest -q
.venv\Scripts\python -m ruff check .
.venv\Scripts\python -m ruff format .
```

Les tests n'appellent jamais Google, VirusTotal ou RDAP : `tests/fakes.py` les simule.

## Points d'entrée

| Méthode | Chemin | Rôle |
| --- | --- | --- |
| GET | `/health` | Le serveur répond |
| POST | `/analyse` | Reçoit un `AnalyseRequest`, renvoie un `Verdict` |
| POST | `/feedback` | Reçoit une note ou un signalement |

Les modèles sont dans `phishguard_server/models.py` ; les exemples JSON partagés avec l'app
sont dans `../contracts/`.
