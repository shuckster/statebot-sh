# shellcheck shell=sh

#
# FAILURE COUNT HELPERS
#

load_fail_count_for_this_session ()
{
  if [ -f "${CC_FAILURE_COUNT_FILE}" ]
  then
    CC_FAILURE_COUNT=$(cat "${CC_FAILURE_COUNT_FILE}")
  fi
}

bump_fail_count_for_this_session ()
{
  : $(( CC_FAILURE_COUNT += 1 ))
  echo "${CC_FAILURE_COUNT}" > "${CC_FAILURE_COUNT_FILE}"
  warn "Failure count: ${CC_FAILURE_COUNT}"
}

unbump_fail_count_for_this_session ()
{
  : $(( CC_FAILURE_COUNT -= 1 ))
  if [ "${CC_FAILURE_COUNT}" -lt 0 ]
  then
    CC_FAILURE_COUNT=0
  fi
  echo "${CC_FAILURE_COUNT}" > "${CC_FAILURE_COUNT_FILE}"
  log "Failure count: ${CC_FAILURE_COUNT}"
}

we_have_failed_enough_to_try_a_reboot ()
{
  if [ "${CC_FAILURE_COUNT}" -ge "${CC_FAILURE_LIMIT_BEFORE_REBOOT}" ]
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
