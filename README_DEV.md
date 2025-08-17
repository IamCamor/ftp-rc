VS Code Pack for FishTrackPro
=============================

Place `.vscode/` and `dev.sh` into your project root (next to `backend/` and `frontend/`).

Run
---
- API mode: VS Code → Run and Debug → "FishTrackPro: Run All (API)"
- Mocks only: VS Code → Run and Debug → "FishTrackPro: Run Front (mocks)"

Frontend .env
-------------
VITE_USE_MOCKS=false
VITE_API_BASE=http://127.0.0.1:8000/api

Notes
-----
- For PHP debugging, enable Xdebug (port 9003) and use config "PHP: Listen for Xdebug".
- Or run `./dev.sh` in terminal to start all processes.
