# Cloud Run image for the DevPilot API and AI gateway.
# Build from the REPOSITORY ROOT:  docker build -f services/api/Dockerfile .   (Cloud Build: services/api/cloudbuild.yaml)

# Stage 1: turn content/labs into a small public catalogue. The lab sources (tests, solutions) never reach the image.
FROM python:3.12-slim AS catalog
RUN pip install --no-cache-dir pyyaml
WORKDIR /srv
COPY services/api/app ./app
COPY content/labs /labs
RUN python -m app.db.catalog /labs /catalog.json

# Stage 2: the service.
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN useradd --create-home --uid 10001 app
WORKDIR /srv
COPY services/api/pyproject.toml services/api/README.md ./
COPY services/api/app ./app
RUN pip install --no-cache-dir .
COPY --from=catalog /catalog.json /srv/catalog.json
USER app
# Production settings: Gemini and Firestore through the service identity (no keys). The dev-only lab verifier and
# dev tokens refuse to run when the environment is not "dev".
ENV DEVSPHERE_ENVIRONMENT=prod DEVSPHERE_AI_PROVIDER=gemini DEVSPHERE_DATABASE=firestore DEVSPHERE_CATALOG_FILE=/srv/catalog.json
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}"]
