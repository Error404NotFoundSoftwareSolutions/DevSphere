# Cloud Run image for the DevSphere/BuildLoop API and AI gateway.
# NOT built or deployed from this repository yet (see docs/buildathon/DEPLOY_CLOUD_RUN.md for what must change first).
FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN useradd --create-home --uid 10001 app
WORKDIR /srv
COPY pyproject.toml README.md ./
COPY app ./app
RUN pip install --no-cache-dir .
USER app
# Production settings: Gemini through the service identity (no key). The dev-only lab verifier refuses to run here.
ENV DEVSPHERE_ENVIRONMENT=prod DEVSPHERE_AI_PROVIDER=gemini
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT:-8080}"]
