#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ids live in .env (gitignored) - copy .env.example to .env and fill it in
set -a
source "${REPO_ROOT}/.env"
set +a
: "${BUCKET_NAME:?set BUCKET_NAME in .env}"
: "${DISTRIBUTION_ID:?set DISTRIBUTION_ID in .env}"

#build
build() {
  echo "Building..."
  npm --prefix ${REPO_ROOT}/site run build
  echo "Finished building..."
}
#aws s3 sync
s3_sync() {
  echo "Syncing to S3..."
  aws s3 sync ${REPO_ROOT}/site/dist \
  s3://${BUCKET_NAME}/ \
  --delete
  echo "Finished Syncing to S3..."
}
#invalidate index.html
invalidate_index_html() {
  echo "Invalidating index.html..."
  aws cloudfront create-invalidation --distribution-id ${DISTRIBUTION_ID} --paths "/" "/index.html"
  echo "Finished invalidating - the process may take some time to invalidate the index.html..."
}

init() {
  build
  s3_sync
  invalidate_index_html

  echo "Finished deploying..."
}

init

# for now the script is invalidating the index.html ( which invalidates all the assets related to it)
# when deploying the s3 you can pass the header --cache-control "public,max-age=31536000,immutable
# in this case you're telling the CDN and also the browser that you wanna keep that file in cache for
# a year (31536000 seconds) and that it's immutable (it's not gonna change)

# the next example you cache all the assets except the index.html

# aws s3 sync "${dist}" "${bucket}/" \
#   --delete \
#   --exclude "index.html" \
#   --cache-control "public,max-age=31536000,immutable"

# aws s3 cp "${dist}/index.html" "${bucket}/index.html" \
#   --cache-control "no-cache"