# link-stability
link-stability.sh is a Bash script for characterizing flaky network links.
Troubleshooting intermittent problems is difficult in nearly all cases, but
it's particularly difficult when trying to troubleshoot problems with a network
link to a consumer ISP.

The purpose of this script is to help the troubleshooting process by providing
precise data about the time and duration of link problems.

```
link-stability.sh <target> [timeout] [retry-grace]
```

Arguments:
- `target`: hostname or IP address to ping
- `timeout`: length of time (in seconds) to wait for the ping response 
             (default: 1)
- `retry-grace`: number of failed pings before link is declared down 
             (default: 2)

The script will run until it is canceled with Ctrl-C, at which point it will
summarize the results and exit.

The value of `target` should be an IP address (FQDNs are not recommended - 
adding the DNS lookup step will throw off the results) that is expected to 
*always* be reachable via ping. The script will use ping failures to 
characterize the link, so it's important that the target IP be one that will
always be up. For testing open Internet connections, 8.8.8.8 (one of Google's
public DNS servers) is a reasonable choice.

The `timeout` is the amount of time (in seconds) to wait for each ping before 
declaring it to be lost. The default is 1 second, which should be suitable for
anything except high latency links (such as dial-up modem or geostationary
satellite links). If the maximum reported latency approaches 1,000ms, consider
specifying a different value for `timeout`.

The `retry-grace` is the number of failed pings necessary before the script
considers the link to be dead. The purpose of this is to adjust the sensitivity
of the script; if there is a reasonable expectation that the link should 
_never_ drop packets, this can be set to 0. Increasing this value quiets the
output, showing only when the link loses consecutive pings. It still keeps
track of the nubmer of times that it had to do grace retries, and will display
that figure in the exit summary. It should also be noted that even when using
a non-0 value for `retry-grace`, the time that is displayed for the beginning
of the outage will still be accurate.

---
### Sample Output
```
~$ .//link-stability.sh 8.8.8.8 1 2
Starting at Tue 23 Jun 2020 11:41:01 PM CDT at 8.8.8.8 (1s ping timeout), 2 retry grace
8.8.8.8 beginning the run in reachable state
8.8.8.8 unreachable at Wed 24 Jun 2020 05:09:25 AM CDT after 19704 seconds up... reachable again at Wed 24 Jun 2020 05:09:28 AM CDT after 3 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 05:09:31 AM CDT after 3 seconds up... reachable again at Wed 24 Jun 2020 05:09:34 AM CDT after 3 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 05:09:35 AM CDT after 1 seconds up... reachable again at Wed 24 Jun 2020 05:09:39 AM CDT after 4 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 05:09:58 AM CDT after 19 seconds up... reachable again at Wed 24 Jun 2020 05:10:01 AM CDT after 3 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 05:15:38 AM CDT after 337 seconds up... reachable again at Wed 24 Jun 2020 05:15:41 AM CDT after 3 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 05:45:34 AM CDT after 1793 seconds up... reachable again at Wed 24 Jun 2020 05:45:37 AM CDT after 3 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 08:00:58 AM CDT after 8121 seconds up... reachable again at Wed 24 Jun 2020 08:01:12 AM CDT after 14 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 09:28:10 AM CDT after 5218 seconds up... reachable again at Wed 24 Jun 2020 09:28:14 AM CDT after 4 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:45:59 PM CDT after 47865 seconds up... reachable again at Wed 24 Jun 2020 10:46:03 PM CDT after 4 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:46:07 PM CDT after 4 seconds up... reachable again at Wed 24 Jun 2020 10:46:13 PM CDT after 6 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:46:16 PM CDT after 3 seconds up... reachable again at Wed 24 Jun 2020 10:46:20 PM CDT after 4 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:46:21 PM CDT after 1 seconds up... reachable again at Wed 24 Jun 2020 10:46:26 PM CDT after 5 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:46:27 PM CDT after 1 seconds up... reachable again at Wed 24 Jun 2020 10:46:31 PM CDT after 4 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:46:32 PM CDT after 1 seconds up... reachable again at Wed 24 Jun 2020 10:46:38 PM CDT after 6 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:46:45 PM CDT after 7 seconds up... reachable again at Wed 24 Jun 2020 10:46:49 PM CDT after 4 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:47:02 PM CDT after 13 seconds up... reachable again at Wed 24 Jun 2020 10:47:11 PM CDT after 9 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:47:16 PM CDT after 5 seconds up... reachable again at Wed 24 Jun 2020 10:47:21 PM CDT after 5 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:47:33 PM CDT after 12 seconds up... reachable again at Wed 24 Jun 2020 10:47:36 PM CDT after 3 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:48:07 PM CDT after 31 seconds up... reachable again at Wed 24 Jun 2020 10:48:10 PM CDT after 3 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:49:21 PM CDT after 71 seconds up... reachable again at Wed 24 Jun 2020 10:49:25 PM CDT after 4 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:49:26 PM CDT after 1 seconds up... reachable again at Wed 24 Jun 2020 10:49:35 PM CDT after 9 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:49:37 PM CDT after 2 seconds up... reachable again at Wed 24 Jun 2020 10:49:53 PM CDT after 16 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:49:56 PM CDT after 3 seconds up... reachable again at Wed 24 Jun 2020 10:50:09 PM CDT after 13 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:50:19 PM CDT after 10 seconds up... reachable again at Wed 24 Jun 2020 10:50:22 PM CDT after 3 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:50:23 PM CDT after 1 seconds up... reachable again at Wed 24 Jun 2020 10:50:26 PM CDT after 3 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:50:45 PM CDT after 19 seconds up... reachable again at Wed 24 Jun 2020 10:50:49 PM CDT after 4 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:51:23 PM CDT after 34 seconds up... reachable again at Wed 24 Jun 2020 10:51:26 PM CDT after 3 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:51:27 PM CDT after 1 seconds up... reachable again at Wed 24 Jun 2020 10:51:30 PM CDT after 3 seconds down
8.8.8.8 unreachable at Wed 24 Jun 2020 10:51:32 PM CDT after 2 seconds up... reachable again at Wed 24 Jun 2020 10:51:36 PM CDT after 4 seconds down
^C
Finished Wed 24 Jun 2020 11:01:00 PM CDT
Min ping latency: 11 ms
Max ping latency: 952 ms
Average latency:  32 ms
Min uptime: 1 seconds
Max uptime: 47865 seconds
Avg uptime: 2871 seconds
Min downtime: 3 seconds
Max downtime: 16 seconds
Avg downtime: 5 seconds
222 grace retries were used
```

---
### Dependencies
The `link-stability.sh` script requires the following programs to be installed
and available on the path:
- bash
- ping
- bc
- grep
