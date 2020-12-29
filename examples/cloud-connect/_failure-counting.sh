# shellcheck shell=sh

#
# FAILURE COUNT HELPERS
#

load_fail_count_for_this_session ()
{
  if [ -f "${CLOUD_CONNECT_ERRORS}" ]
  then
    FAILURE_COUNT=$(cat "${CLOUD_CONNECT_ERRORS}")
  fi
}

bump_fail_count_for_this_session ()
{
  : $((FAILURE_COUNT+=1))
  echo "${FAILURE_COUNT}" > "${CLOUD_CONNECT_ERRORS}"
  warn "Failure count: ${FAILURE_COUNT}"
}

unbump_fail_count_for_this_session ()
{
  : $((FAILURE_COUNT-=1))
  if [ "${FAILURE_COUNT}" -lt 0 ]
  then
    FAILURE_COUNT=0
  fi
  echo "${FAILURE_COUNT}" > "${CLOUD_CONNECT_ERRORS}"
  log "Failure count: ${FAILURE_COUNT}"
}

we_have_failed_enough_to_try_a_reboot ()
{
  if [ "${FAILURE_COUNT}" -ge "${FAILURE_LIMIT}" ]
  then
    return 0
  fi
  return 1
}

try_a_reboot_if_necessary ()
{
  if ! we_have_failed_enough_to_try_a_reboot
  then
    log "Retry limit not yet reached..."
    return 1
  fi

  warn "Failure limit reached! Are we allowed to try a reboot?"

  if ! is_reboot_allowed
  then
    log "Not rebooting!"
    return 1
  fi

  warn "Rebooting!"
  reboot
}
