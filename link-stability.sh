#!/bin/bash
# link-stability.sh - reports on ping loss to a specific destination
#
# Usage:
#   link-stability.sh <target> [timeout] [retry-grace]
#
# Arguments:
#   target: hostname or IP address to ping
#   timeout: length of time (in seconds) to wait for ping response (default: 1)
#   retry-grace: number of failed pings before link is declared down (default: 2)
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
GRACE=${3}
if [[ -z "${GRACE}" ]]; then
  GRACE=2
fi

# Initialize counters
LATENCY_COUNT=0
LATENCY_SUM=0
UPTIME_COUNT=0
UPTIME_SUM=0
DOWNTIME_COUNT=0
DOWNTIME_SUM=0
GRACE_COUNT=0

# Handle ctrl-c events
trap ctrl_c INT
function ctrl_c() {
  echo ""
  echo "Finished $(date)"
  if [[ -n "${MIN}" ]]; then
    echo "Min ping latency: ${MIN} ms"
    echo "Max ping latency: ${MAX} ms"
    if [[ -n "${LATENCY_COUNT}" ]]; then
      echo "Average latency:  $(($LATENCY_SUM/$LATENCY_COUNT)) ms"
    fi
  else
    echo "No min/max latency available"
  fi

  if [[ -n "${MIN_UP}" ]]; then
    echo "Min uptime: ${MIN_UP} seconds"
    echo "Max uptime: ${MAX_UP} seconds"
    if [[ -n "${UPTIME_COUNT}" ]]; then
      echo "Avg uptime: $(($UPTIME_SUM/$UPTIME_COUNT)) seconds"
    fi
  else
    echo "No uptime stats available"
  fi

  if [[ -n "${MIN_DOWN}" ]]; then
    echo "Min downtime: ${MIN_DOWN} seconds"
    echo "Max downtime: ${MAX_DOWN} seconds"
    if [[ -n "${DOWNTIME_COUNT}" ]]; then
      echo "Avg downtime: $(($DOWNTIME_SUM/$DOWNTIME_COUNT)) seconds"
    fi
  else
    echo "No downtime stats available"
  fi

  if [[ "${GRACE_COUNT}" == "0" ]]; then
    echo "No grace retries were used"
  else
    echo "${GRACE_COUNT} grace retries were used"
  fi

  exit 0
}

echo "Starting at $(date) at ${TARGET} (${TIMEOUT}s ping timeout), ${GRACE} retry grace"
WAS_UP=""
while [[ true ]]; do
  # Run the ping, and gather the latency
  EXIT_GRACE=${GRACE}
  until [[ "${EXIT_GRACE}" == "0" ]]; do
    LATENCY=$(ping -c 1 -W ${TIMEOUT} ${TARGET} 2> /dev/null | \
            grep -Po '(?<=time=)[0-9]*')
    PINGABLE=${?}

    if [[ "${PINGABLE}" == "0" ]]; then
      # If the ping worked, there is no need to make use of the grace period
      EXIT_GRACE=0
    else
      # If the ping didn't work, retry. We decrement the grace marker so that
      # we know when to give up and declare the link to be dead
      EXIT_GRACE=$(($EXIT_GRACE-1))

      if [[ ${EXIT_GRACE} -gt 0 ]]; then
        # Also make note that we had to make use of this grace period, so that
        # the total number of such incidents can be reported to the user
        GRACE_COUNT=$((GRACE_COUNT+1))
      fi
    fi
  done

  # Update min / max latency figures
  if [[ "${PINGABLE}" == "0" ]]; then
    LATENCY_SUM=$(($LATENCY_SUM+$LATENCY))
    LATENCY_COUNT=$(($LATENCY_COUNT+1))
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
      INTERVAL=$(($NOW-$LAST_CHANGE))
      LAST_CHANGE=${NOW}

      if [[ "${WAS_UP}" == "0" ]]; then
        # Since the target was pingable before the state cange, but is not
        # now, this is the end of a period of uptime. The first thing we have
        # to do is account for the any grace retry intervals, because if we're
        # at this point in the code, they've been used up. We also deduct from
        # the GRACE_COUNT, because it should *only* count the cases where grace
        # was extended; not cases where it was exceeded. This allows the user
        # to evaluate how many times the grace retry prevented a declaration
        # that the link was dead
        LAST_CHANGE=$(($LAST_CHANGE-($TIMEOUT*$GRACE)))
        INTERVAL=$(($INTERVAL-($TIMEOUT*$GRACE)))
        GRACE_COUNT=$(($GRACE_COUNT-$GRACE+1))

        # Collect uptime data for average
        UPTIME_SUM=$(($UPTIME_SUM+$INTERVAL))
        UPTIME_COUNT=$(($UPTIME_COUNT+1))

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

        ACTUAL_STOP=$(date -d "@${LAST_CHANGE}")
        printf "${TARGET} unreachable at ${ACTUAL_STOP} after ${INTERVAL} seconds up... "
      else
        # Since the target was not pingable before the state change, but is
        # now, this is the end of a period of downtime

        # Collect uptime data for average
        DOWNTIME_SUM=$(($DOWNTIME_SUM+$INTERVAL))
        DOWNTIME_COUNT=$(($DOWNTIME_COUNT+1))

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
  # the link (if the ping worked; if not, the ping timeout will have
  # accomplished the same end)
  WAS_UP=${PINGABLE}
  if [[ "${PINGABLE}" == "0" ]]; then
    sleep 1
  fi
done
