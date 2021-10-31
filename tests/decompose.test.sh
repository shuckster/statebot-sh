#!/bin/sh
# shellcheck disable=SC1091,SC2219,SC2039,SC3043
. ./_assert.sh

CHART_1='
  idle -> pending -> (rejected | resolved) -> finished
'

CHART_2='
  idle -> pending
  pending -> (rejected | resolved)
  (rejected | resolved) -> finished
'

CHART_3='
  idle -> pending
  pending -> rejected
  pending -> resolved
  rejected -> finished
  resolved -> finished
'

CHART_4='
  rejected -> finished
  resolved -> finished
  idle -> pending
  pending -> (rejected |
  resolved)
'

# Import Statebot and initialise it
cd "${0%/*}" || exit 255
# shellcheck disable=SC2034
STATEBOT_LOG_LEVEL=4
. ../statebot.sh

CHART_TRANSITIONS='idle->pending
pending->rejected
pending->resolved
rejected->finished
resolved->finished'

CHART_STATES='idle
pending
rejected
resolved
finished'

run_test_against_chart ()
{
  local chart_name chart test_transitions test_states

  chart_name="$1"
  chart="$2"
  test_transitions=$(decompose_chart "${chart}")
  test_states=$(decompose_transitions "${test_transitions}")

  assert_list_eq "${test_transitions}" "${CHART_TRANSITIONS}" \
    "${chart_name} :: Transitions match test"
  assert_list_eq "${test_states}" "${CHART_STATES}" \
    "${chart_name} :: States match test"
}

run_test_against_chart "CHART_1" "${CHART_1}"
run_test_against_chart "CHART_2" "${CHART_2}"
run_test_against_chart "CHART_3" "${CHART_3}"
run_test_against_chart "CHART_4" "${CHART_4}"

assert_describe "decompose_transitions() & decompose_states() do the right thing"
exit $?
