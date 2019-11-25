#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export HOST_GIT_ROOT="$DIR/.."
export GIT_ROOT="/opt/git"

if [ -z "$1" ]; then
    TEST=""
else
    TEST="/$1"
fi

echo "Building test runner Docker image (please be patient first time)..."
TEST_RUNNER_IMAGE_ID="$(docker build -q $DIR)"
echo "Done"

echo "Build gluu-gateway-lua-deps.tag.gz"
${HOST_GIT_ROOT}/setup/make-gg-lua-deps-archive.sh
echo "Done"

echo "Build gluu-gateway docker image"
export GG_IMAGE_ID="$(docker build -q -f $HOST_GIT_ROOT/Dockerfile.gluu_gateway $HOST_GIT_ROOT)"
echo "Done"

docker run --net host --rm -v /var/run/docker.sock:/var/run/docker.sock \
    -v $HOST_GIT_ROOT:$GIT_ROOT \
    -v /tmp:/tmp \
    --env HOST_GIT_ROOT --env GIT_ROOT --env GG_IMAGE_ID \
    $TEST_RUNNER_IMAGE_ID busted -m=$GIT_ROOT/t/lib/?.lua $GIT_ROOT/t/specs$TEST
