#!/bin/bash
# shellcheck disable=SC2219

# Get the plugins available
cd "${0%/*}" || exit 255
PLUGINS="$(find ./plugins -iname 'api.sh')"

# If there's only one plugin, we save its name
let PLUGIN_COUNT=0
FIRST_PLUGIN=""
for NEXT_PLUGIN in ${PLUGINS}
do
  if [[ $PLUGIN_COUNT -eq 0 ]]
  then
    FIRST_PLUGIN="$NEXT_PLUGIN"
  else
    FIRST_PLUGIN=""
  fi
  let PLUGIN_COUNT+=1
done

# None at all? :(
if [[ $PLUGIN_COUNT -eq 0 ]]
then
  echo "No plugins available :("
  exit 0
fi

# If there's only 1 plugin, load it by default and
# assume the first argument (if specified) will be
# an event to emit instead of a plugin-name.
EXIT_CODE=1
if [[ $PLUGIN_COUNT -eq 1 ]]
then
  PLUGIN_NAME=$(echo "$FIRST_PLUGIN" | awk '
    BEGIN { FS="/" } { print $3 }
  ')
  EXIT_CODE=2
else
  PLUGIN_NAME="$1"
  if [[ "$PLUGIN_NAME" != "" ]]
  then
    shift 1
  fi
fi

# More than 2, but none specified
if [[ "$PLUGIN_NAME" == "" ]]
then
  echo "Please specify a plugin to use. You have a few:"
  echo "${PLUGINS}" | awk 'BEGIN { FS="/" } { print "  " $3 }'
  exit 3
fi

# We now have a plugin-name, so get the API and load it
PLUGIN_PATH="./plugins/$PLUGIN_NAME"
PLUGIN_API=$(echo "${PLUGINS}" | grep -e "$PLUGIN_PATH/api.sh")
EVENT="$1"

echo "$PLUGIN_NAME" "$PLUGIN_PATH" "$PLUGIN_API" "$EVENT"
exit "$EXIT_CODE"
