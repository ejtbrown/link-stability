# link-stability
link-stability.sh is a Bash script for characterizing flaky network links.
Troubleshooting intermittent problems is difficult in nearly all cases, but
it's particularly difficult when trying to troubleshoot problems with a network
link to a consumer ISP.

The purpose of this script is to help the troubleshooting process by providing
precise data about the time and duration of link problems.

```
link-stability.sh <target> [timeout]
```

The script will run until it is canceled with Ctrl-C, at which point it will
summarize the results and exit.

The value of `target` should be an IP address (not a FQDN - adding the DNS
lookup step will throw off the results) that is expected to *always* be
reachable via ping. The script will use ping failures to characterize the link,
so it's important that the target IP be one that will always be up. For testing
open Internet connections, 8.8.8.8 (one of Google's public DNS servers) is a
reasonable choice.

The `timeout` is the amount of time (in seconds) to wait for each ping before declaring it to be lost. The default is 1 second, which should be suitable for
anything except high latency links (such as dial-up modem or geostationary
satellite links). If the maximum reported latency approaches 1,000ms, consider
specifying a different value for `timeout`.

---
### Sample Output
```
~$ ./link-stability.sh 8.8.8.8
Starting at Tue 19 May 2020 12:18:33 PM CDT at 8.8.8.8 (1s ping timeout)
8.8.8.8 beginning the run in reachable state
8.8.8.8 unreachable at Tue 19 May 2020 12:26:19 PM CDT after 466 seconds up... reachable again at Tue 19 May 2020 12:26:30 PM CDT after 11 seconds down
8.8.8.8 unreachable at Tue 19 May 2020 12:27:01 PM CDT after 31 seconds up... reachable again at Tue 19 May 2020 12:27:02 PM CDT after 1 seconds down
8.8.8.8 unreachable at Tue 19 May 2020 12:27:11 PM CDT after 9 seconds up... reachable again at Tue 19 May 2020 12:27:30 PM CDT after 19 seconds down
8.8.8.8 unreachable at Tue 19 May 2020 12:58:28 PM CDT after 1858 seconds up... reachable again at Tue 19 May 2020 12:58:29 PM CDT after 1 seconds down
8.8.8.8 unreachable at Tue 19 May 2020 12:58:32 PM CDT after 3 seconds up... reachable again at Tue 19 May 2020 12:58:33 PM CDT after 1 seconds down
^C
Finished Tue 19 May 2020 01:18:01 PM CDT
Min ping latency: 11 ms
Max ping latency: 86 ms
Min uptime: 3 seconds
Max uptime: 1858 seconds
Avg uptime: 473 seconds
Min downtime: 1 seconds
Max downtime: 19 seconds
Avg downtime: 6 seconds
```

---
### Dependencies
The `link-stability.sh` script requires the following programs:
- bash
- ping
- bc
- grep
