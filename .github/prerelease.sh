#!/usr/bin/env bash

set -e

RELEASE_ID=$(curl -sL https://api.github.com/repos/${REPOSITORY}/releases/tags/edge | jq -r .id)
HEAD_SHA=$(curl -sL https://api.github.com/repos/${REPOSITORY}/git/refs/heads/main | jq -r .object.sha)
PRERELEASE_TAG=$(git describe --always --abbrev=7 --tags --exclude=edge)

function cleanup {
  git tag -d ${PRERELEASE_TAG} || true
  git fetch --tags -f || true
}

trap cleanup EXIT
git fetch --tags -f
git tag -f ${PRERELEASE_TAG}

goreleaser release \
    --rm-dist \
    --skip-validate \
    -f .goreleaser.pre.yml

curl -sL \
    -X PATCH \
    -u "_:${GITHUB_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    -d '{"sha":"'${HEAD_SHA}'","force":"true"}' \
    "https://api.github.com/repos/${REPOSITORY}/git/refs/tags/edge"

# 
for asset_url in $(shell curl -sL -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/${REPOSITORY}/releases/tags/edge | jq ".assets[].url"); do
    echo "deleting edge release asset: ${asset_url}"; \
    curl -sLX DELETE \
        -u _:${GITHUB_TOKEN} \
        "${asset_url}";
done

for asset in $(find dist -type f -name "${NAME}_edge*"); do
    echo "uploading ${asset}.."
    curl -sL \
        -u _:${GITHUB_TOKEN} \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: $(file -b --mime-type ${asset})" \
        --data-binary @${asset} \
        "https://uploads.github.com/repos/${REPOSITORY}/releases/${RELEASE_ID}/assets?name=$(basename $asset)"
done

# Upload snaps to the edge channel
find dist -type f -name "*.snap" -exec snapcraft upload --release edge '{}' \;
