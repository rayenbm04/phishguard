# PhishGuard server image (used by Render, or any host that runs Docker).
FROM python:3.12-slim

WORKDIR /app
COPY pyproject.toml ./
COPY phishguard_server ./phishguard_server
RUN pip install --no-cache-dir .

# Verdicts, feedback and reports (server/var on a PC). Lost when the free host restarts.
ENV DATA_DIR=/app/var
# The host gives the port in $PORT.
ENV PORT=8000
EXPOSE 8000

CMD ["sh", "-c", "uvicorn phishguard_server.main:app --host 0.0.0.0 --port ${PORT}"]
