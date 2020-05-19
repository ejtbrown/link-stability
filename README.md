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
