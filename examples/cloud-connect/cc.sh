#!/bin/sh
cd "${0%/*}" || exit 255

# shellcheck disable=SC1091
. ./_config.sh

./cloud-connect.sh "${CC_PLUGIN}" "$@"
