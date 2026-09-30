#!/usr/bin/env bash

set -euo pipefail

for i in {1..20}; do
  echo "===== Request $i ===== index.html"

  curl -s -D - -o /dev/null \
    -w "TTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n" \
    https://residencia.kmvpsolutions.com/index.html \
    | grep -Ei "x-cache|age|TTFB|Total"

  echo
  sleep 1

  echo "===== Request $i ===== /assets/"

  curl -s -D - -o /dev/null \
    -w "TTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n" \
    https://residencia.kmvpsolutions.com/assets/index-B_ui1e4G.css \
    | grep -Ei "x-cache|age|TTFB|Total"

  echo
  sleep 1
done
