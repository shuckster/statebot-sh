#!/bin/bash

# At this point, PLUGIN_PATH is available for you to import
# credentials and configuration from other files, if you like!

# source "${PLUGIN_PATH}/.secrets"
# source "${PLUGIN_PATH}/config.sh"

is_valid_network ()
{
  log "Are we on the right network to do this?"
  return 0 # Non-zero here means "nope!"
}

is_logged_in ()
{
  # Just ping Google for this demo...
  ping -t 3 google.com
  return $? # Non-zero here means an error occurred
}

login ()
{
  sleep 3
  return 0 # Non-zero here means an error occurred
}

is_reboot_allowed ()
{
  return 1 # Non-zero here means "nope!"
}

report_online_status ()
{
  echo "Maybe POST to a URL so you can graph your connection-status!"
}
