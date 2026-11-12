#!/usr/bin/env bash
# Builds the DevPilot API image with Cloud Build and deploys it to Cloud Run. One command, from anywhere in the repo:
#   tools/deploy_api.sh            (project devpilot-app, region asia-south1)
# It runs the API tests first and stops if they fail. Nothing secret is read or printed.
set -euo pipefail
cd "$(dirname "$0")/.."

PROJECT="${DEVPILOT_GCP_PROJECT:-devpilot-app}"
REGION="${DEVPILOT_GCP_REGION:-asia-south1}"
SERVICE="${DEVPILOT_CLOUD_RUN_SERVICE:-devpilot-api}"
IMAGE="$REGION-docker.pkg.dev/$PROJECT/devpilot/api:$(date +%Y%m%d-%H%M%S)"

echo "--> Running the API tests"
uv run pytest services/api -q

echo "--> Building $IMAGE"
gcloud builds submit --config services/api/cloudbuild.yaml \
  --ignore-file services/api/.cloudbuildignore \
  --substitutions "_IMAGE=$IMAGE" --project "$PROJECT" .

echo "--> Deploying $SERVICE (settings stay as they are; only the image changes)"
gcloud run deploy "$SERVICE" --image "$IMAGE" --region "$REGION" --project "$PROJECT" --quiet

URL="$(gcloud run services describe "$SERVICE" --region "$REGION" --project "$PROJECT" --format='value(status.url)')"
echo "--> Checking $URL/health"
curl -fsS "$URL/health" && echo
echo "Done. $URL"
