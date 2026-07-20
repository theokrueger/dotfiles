#!/bin/bash
# show memory usage of a given PID

if [[ "$1" == "" ]]; then
  echo "usage: mem-usage.sh <PID>"
  exit
fi

pid="$1"
page_size=$(getconf PAGE_SIZE)
rss_pages=$(cat /proc/$pid/statm | awk '{print $2}')
rss_kb=$((rss_pages * page_size / 1024))
echo "Process $pid is using $rss_kb KiB of memory."
rss_mb=$(printf "%.02f" $(echo $rss_kb / 1024 | bc -l))
rss_gb=$(printf "%.02f" $(echo $rss_mb / 1024 | bc -l))
echo "That's $rss_mb MiB or $rss_gb GiB"
