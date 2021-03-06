#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export HOST_GIT_ROOT="$DIR/.."
export GIT_ROOT="/opt/git"

if [ -z "$1" ]; then
    echo "Please specify the flow"
    exit 1
else
    TEST="/$1"
fi

echo "Building test runner Docker image (please be patient first time)..."
TEST_RUNNER_IMAGE_ID="$(docker build -q $DIR)"
if [ -z "$TEST_RUNNER_IMAGE_ID" ]
then
    echo "test runner image build error"
    exit 1
fi
echo "Done"

echo "Build gluu-gateway docker image"
export GG_IMAGE_ID="$(docker build -q -f $HOST_GIT_ROOT/Dockerfile $HOST_GIT_ROOT)"
if [ -z "$GG_IMAGE_ID" ]
then
    echo "gluu-gateway image build error"
    exit 1
fi
echo "Done"

docker run --net host --rm -v /var/run/docker.sock:/var/run/docker.sock \
    -v $HOST_GIT_ROOT:$GIT_ROOT \
    -v /tmp:/tmp \
    --env HOST_GIT_ROOT --env GIT_ROOT --env GG_IMAGE_ID \
    $TEST_RUNNER_IMAGE_ID busted -m=$GIT_ROOT/t/lib/?.lua $GIT_ROOT/t/specs$TEST
