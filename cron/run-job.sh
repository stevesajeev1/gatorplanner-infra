#!/usr/bin/env bash

set -Eeuo pipefail

JOB="${1:?usage: run-job.sh <script.py> [args...]}"

case "$JOB" in
    scrape_buildings.py)
        ;;
    scrape_rmp.py)
        ;;
    scrape_uf.py)
        ;;
    sync-elasticsearch.py)
        ;;
    *)
        echo "Unknown job: $JOB" >&2
        exit 1
        ;;
esac

JOB_NAME="${JOB%.py}"

shift

LOCK_FILE="/tmp/gatorplanner-${JOB_NAME}.lock"
NETWORK="gatorplanner"
ENV_FILE="/opt/projects/gatorplanner/.env"

set -a
source "$ENV_FILE"
set +a

IMAGE="ghcr.io/${GITHUB_OWNER}/gatorplanner-jobs:latest"

exec 9>"$LOCK_FILE"

if ! flock -n 9; then
    echo "[$JOB_NAME] already running; skipping"
    exit 0
fi

exec > >(logger -t "gatorplanner-$JOB_NAME") 2>&1

echo "[$JOB_NAME] starting"

echo "[$JOB_NAME] pulling jobs image"
docker pull "$IMAGE"

echo "[$JOB_NAME] running"
docker run --rm \
    --network "$NETWORK" \
    --env-file "$ENV_FILE" \
    "$IMAGE" \
    python "$JOB" "$@"

echo "[$JOB_NAME] completed successfully"