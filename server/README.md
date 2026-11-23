# Serveur PhishGuard

API FastAPI (Python 3.10 ou plus, 3.12 en CI). Étape 1 : le contrat JSON est réel,
l'analyse renvoie encore un verdict `UNSURE` de remplacement.

## Lancer en local (PowerShell)

```powershell
cd server
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -e ".[dev]"
uvicorn phishguard_server.main:app --reload
```

Puis ouvrir http://127.0.0.1:8000/docs pour tester `/health`, `/analyse` et `/feedback`.

## Tests et style

```powershell
pytest -q
ruff check .
ruff format .
```

## Points d'entrée

| Méthode | Chemin | Rôle |
| --- | --- | --- |
| GET | `/health` | Le serveur répond |
| POST | `/analyse` | Reçoit un `AnalyseRequest`, renvoie un `Verdict` |
| POST | `/feedback` | Reçoit une note ou un signalement |

Les modèles sont dans `phishguard_server/models.py` ; les exemples JSON partagés avec l'app
sont dans `../contracts/`.

Les clés d'API vont dans `server/.env` (copier `.env.example`), jamais dans Git.
