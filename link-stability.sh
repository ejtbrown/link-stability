#!/bin/bash
# link-stability.sh - reports on ping loss to a specific destination
#
# Usage:
#   link-stability.sh <target> [timeout]
#
# Authors:
#   Erick Brown <ejtbpublic@gmail.com>
#
# License:
#   GPL 3.0; software is free for use as-is, no warranty is granted or should
#   be assumed

TARGET=${1}
TIMEOUT=${2}
if [[ -z "${TIMEOUT}" ]]; then
  TIMEOUT=1
fi

# Initialize counters
LATENCY_COUNT=0
LATENCY_SUM=0
UPTIME_COUNT=0
UPTIME_SUM=0
DOWNTIME_COUNT=0
DOWNTIME_SUM=0

# Handle ctrl-c events
trap ctrl_c INT
function ctrl_c() {
  echo ""
  echo "Finished $(date)"
  if [[ -n "${MIN}" ]]; then
    echo "Min ping latency: ${MIN} ms"
    echo "Max ping latency: ${MAX} ms"
    echo "Average latency:  $((${LATENCY_SUM}/${LATENCY_COUNT})) ms"
  else
    echo "No min/max latency available"
  fi

  if [[ -n "${MIN_UP}" ]]; then
    echo "Min uptime: ${MIN_UP} seconds"
    echo "Max uptime: ${MAX_UP} seconds"
    echo "Avg uptime: $((${UPTIME_SUM}/${UPTIME_COUNT})) seconds"
  else
    echo "No uptime stats available"
  fi

  if [[ -n "${MIN_DOWN}" ]]; then
    echo "Min downtime: ${MIN_DOWN} seconds"
    echo "Max downtime: ${MAX_DOWN} seconds"
    echo "Avg uptime: $((${DOWNTIME_SUM}/${DOWNTIME_COUNT})) seconds"
  else
    echo "No downtime stats available"
  fi

  exit 0
}

echo "Starting at $(date) at ${TARGET} (${TIMEOUT}s ping timeout)"
WAS_UP=""
while [[ true ]]; do
  # Run the ping, and gather the latency
  LATENCY=$(ping -c 1 -W ${TIMEOUT} ${TARGET} 2> /dev/null | \
            grep -Po '(?<=time=)[0-9]*')
  PINGABLE=${?}

  # Update min / max latency figures
  if [[ "${PINGABLE}" == "0" ]]; then
    LATENCY_SUM=$((${LATENCY_SUM}+${LATENCY}))
    LATENCY_COUNT=$((${LATENCY_COUNT}+1))
    if [[ -z "${MIN}" ]]; then
      MIN=${LATENCY}
      MAX=${LATENCY}
    fi

    if [[ ${MIN} -gt ${LATENCY} ]]; then
      MIN=${LATENCY}
    fi

    if [[ ${MAX} -lt ${LATENCY} ]]; then
      MAX=${LATENCY}
    fi
  fi

  if [[ -z "${WAS_UP}" ]]; then
    if [[ "${PINGABLE}" == "0" ]]; then
      echo "${TARGET} beginning the run in reachable state"
    else
      echo "${TARGET} beginning the run in a non-reachable state"
    fi
    LAST_CHANGE=$(date +%s)
  else
    if [[ "${WAS_UP}" != "${PINGABLE}" ]]; then
      # Calculate the time since the last state change, and save the time of
      # this state change for next time
      NOW=$(date +%s)
      INTERVAL=$((${NOW}-${LAST_CHANGE}))
      LAST_CHANGE=${NOW}

      if [[ "${WAS_UP}" == "0" ]]; then
        # Since the target was pingable before the state cange, but is not
        # now, this is the end of a period of uptime

        # Collect uptime data for average
        UPTIME_SUM=$((${UPTIME_SUM}+${INTERVAL}))
        UPTIME_COUNT=$((${UPTIME_COUNT}+1))

        # Update min/max uptimes
        if [[ -z "${MIN_UP}" ]]; then
          MIN_UP=${INTERVAL}
          MAX_UP=${INTERVAL}
        else
          if [[ ${MIN_UP} -gt ${INTERVAL} ]]; then
            MIN_UP=${INTERVAL}
          fi

          if [[ ${MAX_UP} -lt ${INTERVAL} ]]; then
            MAX_UP=${INTERVAL}
          fi
        fi

        printf "${TARGET} unreachable at $(date) after ${INTERVAL} seconds up... "
      else
        # Since the target was not pingable before the state change, but is
        # now, this is the end of a period of downtime

        # Collect uptime data for average
        DOWMTIME_SUM=$((${DOWMTIME_SUM}+${INTERVAL}))
        DOWMTIME_COUNT=$((${DOWMTIME_COUNT}+1))

        # Update min/max downtimes
        if [[ -z "${MIN_DOWN}" ]]; then
          MIN_DOWN=${INTERVAL}
          MAX_DOWN=${INTERVAL}
        else
          if [[ ${MIN_DOWN} -gt ${INTERVAL} ]]; then
            MIN_DOWN=${INTERVAL}
          fi

          if [[ ${MAX_DOWN} -lt ${INTERVAL} ]]; then
            MAX_DOWN=${INTERVAL}
          fi
        fi

        printf "reachable again at $(date) after ${INTERVAL} seconds down\n"
      fi
    fi
  fi

  # Save the state for next time, the wait a moment so as to avoid spamming
  # the link
  WAS_UP=${PINGABLE}
  sleep 1

done
