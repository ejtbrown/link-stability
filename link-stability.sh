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

# Handle ctrl-c events
trap ctrl_c INT
function ctrl_c() {
  echo "Finished $(date)"
  if [[ -n "${MIN}" ]]; then
    echo "Min ping latency: ${MIN}"
    echo "Max ping latency: ${MAX}"
  else
    echo "No min/max latency available"
  fi

  if [[ -n "${MIN_UP}" ]]; then
    echo "Min uptime: ${MIN_UP}"
    echo "Max uptime: ${MAX_UP}"
    echo "Avg uptime: $(echo "(${UPS})/${UP_COUNT}" | bc)"
  else
    echo "No uptime stats available"
  fi

  if [[ -n "${MIN_DOWN}" ]]; then
    echo "Min downtime: ${MIN_DOWN}"
    echo "Max downtime: ${MAX_DOWN}"
    echo "Avg downtime: $(echo "(${DOWNS})/${DOWN_COUNT}" | bc)"
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
    if [[ -z "${MIN}" ]]; then
      MIN=${LATENCY}
      MAX=${LATENCY}
    fi

    if [[ ${MIN} -lt ${LATENCY} ]]; then
      MIN=${LATENCY}
    fi

    if [[ ${MAX} -gt ${LATENCY} ]]; then
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

        # Collect uptime intervals
        if [[ -z "${UPS}" ]]; then
          UPS=${INTERVAL}
          UP_COUNT=1
        else
          UPS="${UPS}+${INTERVAL}"
          UP_COUNT=$((${UP_COUNT}+1))
        fi

        # Update average uptimes
        if [[ -z "${MIN_UP}" ]]; then
          MIN_UP=${INTERVAL}
          MAX_UP=${INTERVAL}
        else
          if [[ ${MIN_UP} -lt ${INTERVAL} ]]; then
            MIN_UP=${INTERVAL}
          fi

          if [[ ${MAX_UP} -gt ${INTERVAL} ]]; then
            MAX_UP=${INTERVAL}
          fi
        fi

        printf "${TARGET} unreachable at $(date) after ${INTERVAL} seconds up... "
      else
        # Since the target was not pingable before the state change, but is
        # now, this is the end of a period of downtime

        # Collect downtime intervals
        if [[ -z "${DOWNS}" ]]; then
          DOWNS=${INTERVAL}
          DOWN_COUNT=1
        else
          DOWNS="${DOWNS}+${INTERVAL}"
          DOWN_COUNT=$((${DOWN_COUNT}+1))
        fi

        # Update average downtimes
        if [[ -z "${MIN_DOWN}" ]]; then
          MIN_DOWN=${INTERVAL}
          MAX_DOWN=${INTERVAL}
        else
          if [[ ${MIN_DOWN} -lt ${INTERVAL} ]]; then
            MIN_DOWN=${INTERVAL}
          fi

          if [[ ${MAX_DOWN} -gt ${INTERVAL} ]]; then
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
